class Tag < ApplicationRecord
  has_many :recipe_tags, dependent: :destroy
  has_many :recipes, through: :recipe_tags

  validates :key, presence: true, uniqueness: true

  scope :active, -> { where(active: true).order(:position, :id) }

  def display_label
    label_ja.presence || key
  end
end
