class SavedRecipesController < ApplicationController
  before_action :authenticate_user!

  def index
    @favorite_recipes = current_user
                               .favorite_recipes
                               .includes(:user, :city, :tags)
                               .with_attached_cover_image
                               .merge(Recipe.visible_to(current_user))
                               .order("saved_recipes.created_at DESC")
  end
end
