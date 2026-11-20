class City < ApplicationRecord
  has_many :recipes, dependent: :nullify
  has_many :city_aliases, dependent: :destroy

  accepts_nested_attributes_for :city_aliases, allow_destroy: true

  validates :name_ja, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :country_code, length: { is: 2 }, allow_blank: true
  validate :aliases_unique_within_city

  before_validation :ensure_slug

  scope :ordered_by_locale, -> { order(Arel.sql("COALESCE(name_ja, name_en, slug) ASC")) }

  def display_name
    name_ja.presence || name_en.presence || slug.titleize
  end

  def self.normalize(str)
    CityNormalizer.normalize(str)
  end

  def self.match_by_alias(input)
    normalized = normalize(input)
    return nil if normalized.blank?

    CityAlias.includes(:city).find_by(normalized_name: normalized)&.city
  end

  def self.autocomplete(term, limit: 10)
    normalized = normalize(term)
    return none if normalized.blank?

    left_outer_joins(:city_aliases)
      .where(
        <<~SQL.squish,
          LOWER(COALESCE(name_ja, '')) LIKE :raw
          OR LOWER(COALESCE(name_en, '')) LIKE :raw
          OR LOWER(slug) LIKE :raw
          OR city_aliases.normalized_name LIKE :normalized
        SQL
        raw: "%#{term.to_s.strip.downcase}%",
        normalized: "%#{normalized}%"
      )
      .distinct
      .order(Arel.sql("COALESCE(name_ja, name_en, slug) ASC"))
      .limit(limit)
  end

  private

  def ensure_slug
    self.slug = slug.presence || display_name.to_s.parameterize
  end

  def aliases_unique_within_city
    return if city_aliases.blank?

    seen = {}

    city_aliases.each do |alias_record|
      next if alias_record.normalized_name.blank?

      if seen[alias_record.normalized_name]
        errors.add(:base, "aliases must be unique")
        break
      end
      seen[alias_record.normalized_name] = true
    end
  end
end
