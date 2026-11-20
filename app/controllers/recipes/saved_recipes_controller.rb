module Recipes
  class SavedRecipesController < ApplicationController
    include RecipeScoped

    before_action :authenticate_user!
    before_action :set_recipe
    before_action :ensure_favoritable!, only: :create

    def create
      saved_recipe = current_user.saved_recipes.find_or_initialize_by(recipe: @recipe)
      if saved_recipe.new_record?
        saved_recipe.save!
        EventLogger.log!(event_type: "recipe_save", recipe: @recipe, actor: current_user)
      end

      respond_to do |format|
        format.html { redirect_to recipe_path(@recipe), notice: "お気に入りに追加しました。" }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              helpers.dom_id(@recipe, :favorite_button),
              partial: "shared/components/favorite_button",
              locals: { recipe: @recipe, saved: true }
            ),
            turbo_stream.replace(
              helpers.dom_id(@recipe, :favorite_button_mobile),
              partial: "shared/components/favorite_button_mobile",
              locals: { recipe: @recipe, saved: true }
            )
          ]
        end
      end
    end

    def destroy
      current_user.saved_recipes.where(recipe: @recipe).destroy_all
      respond_to do |format|
        format.html do
          redirect_target = (@recipe.public? || owns_recipe?(@recipe)) ? recipe_path(@recipe) : saved_recipes_path
          redirect_to redirect_target, notice: "お気に入りを解除しました。"
        end
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              helpers.dom_id(@recipe, :favorite_button),
              partial: "shared/components/favorite_button",
              locals: { recipe: @recipe, saved: false }
            ),
            turbo_stream.replace(
              helpers.dom_id(@recipe, :favorite_button_mobile),
              partial: "shared/components/favorite_button_mobile",
              locals: { recipe: @recipe, saved: false }
            )
          ]
        end
      end
    end

    private

    def ensure_favoritable!
      return if @recipe.public? || owns_recipe?(@recipe)

      redirect_to recipes_path, alert: "お気に入りの対象として利用できません。"
    end
  end
end
