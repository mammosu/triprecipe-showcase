class RecipeDay < ApplicationRecord
  MAX_TITLE_LENGTH = 100
  MAX_NOTES_LENGTH = 2000

  belongs_to :recipe
  belongs_to :last_edited_by, class_name: "User", optional: true
  has_many :recipe_steps, -> { order(:position) }, dependent: :destroy, inverse_of: :recipe_day
  include Auditable
  has_paper_trail only: %i[title notes day_order starts_on]

  before_validation :assign_day_order, on: :create

  validates :title, presence: true, length: { maximum: MAX_TITLE_LENGTH }
  validates :day_order,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 1 },
            uniqueness: { scope: :recipe_id }
  validates :notes, length: { maximum: MAX_NOTES_LENGTH }, allow_blank: true
  validates :last_edited_by_email, length: { maximum: 255 }, allow_blank: true

  scope :ordered, -> { order(:day_order) }

  def normalize_recipe_step_positions!
    RecipeDayPositionsService.normalize_positions!(self)
  end
  private

  def assign_day_order
    return if day_order.present? || recipe.blank?

    max_order = recipe.recipe_days.maximum(:day_order)
    self.day_order = max_order.to_i + 1
  end
end
