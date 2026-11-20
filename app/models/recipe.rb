class Recipe < ApplicationRecord
  require "securerandom"

  MAX_TITLE_LENGTH = 100
  MAX_CITY_DISPLAY_LENGTH = 100
  MAX_DESCRIPTION_LENGTH = 2000
  MAX_COVER_IMAGE_SIZE = 5.megabytes
  COVER_IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze

  belongs_to :user
  belongs_to :city, optional: true
  belongs_to :last_edited_by, class_name: "User", optional: true
  belongs_to :forked_from_recipe, class_name: "Recipe", optional: true
  has_one_attached :cover_image
  has_many :recipe_days, -> { order(:day_order) }, dependent: :destroy, inverse_of: :recipe
  has_many :recipe_steps, through: :recipe_days
  has_many :saved_recipes, dependent: :destroy
  has_many :saving_users, through: :saved_recipes, source: :user
  has_many :recipe_share_tokens, dependent: :destroy
  has_many :slug_aliases, class_name: "RecipeSlug", dependent: :destroy
  has_many :recipe_collaborators, dependent: :destroy
  has_many :collaborators, through: :recipe_collaborators, source: :user
  has_many :recipe_tags, dependent: :destroy
  has_many :tags, through: :recipe_tags
  has_many :forks, class_name: "Recipe", foreign_key: :forked_from_recipe_id, dependent: :nullify
  has_many :recipe_reports, dependent: :destroy
  include Auditable
  has_paper_trail only: %i[title description city_display days_count public]

  attribute :public, :boolean, default: true
  attr_accessor :remove_cover_image

  validates :title, presence: true, length: { maximum: MAX_TITLE_LENGTH }
  validates :city_display, length: { maximum: MAX_CITY_DISPLAY_LENGTH }, allow_blank: true
  validates :days_count,
            numericality: {
              allow_nil: true,
              only_integer: true,
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: 60
            }
  validates :description, length: { maximum: MAX_DESCRIPTION_LENGTH }, allow_blank: true
  validates :public, inclusion: { in: [ true, false ] }
  validates :slug, presence: true, uniqueness: true
  validates :last_edited_by_email, length: { maximum: 255 }, allow_blank: true
  validate :cover_image_content_type
  validate :cover_image_size

  before_save :mark_cover_image_for_removal
  before_validation :sync_city_fields
  before_validation :ensure_slug
  before_validation :regenerate_slug_if_needed
  after_commit :archive_previous_slug, on: :update
  # purge is handled manually after successful update to avoid callback recursion

  scope :visible_to, lambda { |user|
    if user.present?
      where(public: true).or(where(user_id: user.id))
    else
      where(public: true)
    end
  }

  scope :with_saved_recipes_count, lambda {
    saved_counts = SavedRecipe.select(:recipe_id, Arel.sql("COUNT(*) AS saved_recipes_count")).group(:recipe_id)

    with(saved_counts: saved_counts)
      .joins("LEFT JOIN saved_counts ON saved_counts.recipe_id = recipes.id")
      .select(<<~SQL.squish)
        recipes.*,
        COALESCE(saved_counts.saved_recipes_count, 0) AS saved_recipes_count,
        COALESCE(saved_counts.saved_recipes_count, 0) AS favorites_count
      SQL
  }
  scope :with_favorites_count, -> { with_saved_recipes_count }
  scope :keyword_search, lambda { |query|
    return all if query.blank?

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query.to_s.strip)}%"
    where("recipes.title LIKE :q OR recipes.description LIKE :q OR recipes.city_display LIKE :q", q: pattern)
  }
  scope :with_city_id, lambda { |city_id|
    return all if city_id.blank?

    if %w[other none].include?(city_id.to_s)
      where(city_id: nil)
    else
      where(city_id: city_id)
    end
  }

  scope :popular_recipes, lambda { |limit: 5|
    recent_saves = SavedRecipe
                   .where("saved_recipes.created_at >= ?", 30.days.ago)
                   .select(:recipe_id, Arel.sql("COUNT(*) AS saved_recipes_count"))
                   .group(:recipe_id)

    with(recent_saves: recent_saves)
      .joins("INNER JOIN recent_saves ON recent_saves.recipe_id = recipes.id")
      .where(public: true)
      .select(<<~SQL.squish)
        recipes.*,
        recent_saves.saved_recipes_count,
        recent_saves.saved_recipes_count AS favorites_count
      SQL
      .order("recent_saves.saved_recipes_count DESC, recipes.updated_at DESC")
      .limit(limit)
  }
  scope :popular_plans, ->(**options) { popular_recipes(**options) }

  # Fetches a recipe by its current slug or a legacy slug.
  # Raises ActiveRecord::RecordNotFound if not found.
  def self.fetch_by_slug!(identifier)
    find_by!(slug: identifier)
  rescue ActiveRecord::RecordNotFound
    RecipeSlug.find_by!(slug: identifier).recipe
  end

  def saved_by?(user)
    return false if user.blank?

    saved_recipes.where(user_id: user.id).exists?
  end

  def city_label
    city_display.presence || city&.display_name
  end

  def slug_location_fragment
    if city.present?
      city.slug
    else
      city_display
    end
  end

  # NOTE: If this method is used in a list context (e.g., for many Recipe records),
  # be sure to eager load recipe_share_tokens to avoid N+1 queries:
  #   Recipe.includes(:recipe_share_tokens)
  def active_share_token
    recipe_share_tokens.active.order(created_at: :desc).first
  end

  def to_param
    slug.presence || super
  end

  # Collaborator helper methods
  def collaborator?(user)
    return false if user.blank?
    recipe_collaborators.exists?(user: user)
  end

  def editor?(user)
    return false if user.blank?
    recipe_collaborators.exists?(user: user, role: %w[editor admin])
  end

  def admin?(user)
    return false if user.blank?
    recipe_collaborators.exists?(user: user, role: "admin")
  end

  private

  def ensure_slug
    return if slug.present?

    self.slug = generate_unique_slug
  end

  def regenerate_slug_if_needed
    return unless should_regenerate_slug?

    new_slug = generate_unique_slug
    return if slug == new_slug

    self.slug = new_slug
  end

  def generate_unique_slug
    RecipeSlugService.generate_unique_slug_for(self)
  end

  def archive_previous_slug
    return unless saved_change_to_slug?

    previous_slug, = saved_change_to_slug
    slug_aliases.create!(slug: previous_slug) if previous_slug.present?
  end

  def should_regenerate_slug?
    persisted? && (will_save_change_to_title? || will_save_change_to_city_display? || will_save_change_to_city_id?)
  end

  def sync_city_fields
    if city.present? && city_display.blank?
      self.city_display = city.display_name
    elsif city.blank? && city_display.present?
      matched_city = City.match_by_alias(city_display)
      self.city = matched_city if matched_city.present?
    end
  end

  def build_random_slug
    RecipeSlugService.build_random_slug_for(self)
  end

  def cover_image_content_type
    return unless cover_image.attached?

    return if COVER_IMAGE_CONTENT_TYPES.include?(cover_image.content_type)

    errors.add(:cover_image, "はPNG/JPEG/WEBP形式の画像を選択してください")
  end

  def cover_image_size
    return unless cover_image.attached?

    if cover_image.blob.byte_size > MAX_COVER_IMAGE_SIZE
      errors.add(:cover_image, "は5MB以下の画像を選択してください")
    end
  end

  def mark_cover_image_for_removal
    return unless remove_cover_image == "1"
    return unless cover_image.attached?

    @cover_image_should_purge = true
    @auditable_attachment_changes ||= {}
    @auditable_attachment_changes["cover_image"] = { type: :detach, filename: cover_image.filename.to_s }
  end

  def purge_cover_image_if_marked!
    return unless @cover_image_should_purge

    cover_image.purge_later
    @cover_image_should_purge = false
  end
end
