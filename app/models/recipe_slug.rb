class RecipeSlug < ApplicationRecord
  belongs_to :recipe

  validates :slug, presence: true, uniqueness: true
end
