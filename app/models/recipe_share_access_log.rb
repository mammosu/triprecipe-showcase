class RecipeShareAccessLog < ApplicationRecord
  belongs_to :recipe_share_token

  validates :accessed_at, presence: true
end
