module Recipes
  class ShareTokensController < ApplicationController
    include RecipeScoped

    before_action :authenticate_user!
    before_action :set_recipe
    before_action :set_share_token, only: %i[destroy extend_lifespan]

    def create
      authorize @recipe, :manage_share_tokens?
      revoke_existing_tokens
      revoke_existing_tokens
      @recipe.recipe_share_tokens.create!

      redirect_to recipe_path(@recipe), notice: "共有リンクを発行しました。"
    end

    def extend_lifespan
      authorize @recipe, :manage_share_tokens?
      token = @share_token || @recipe.active_share_token
      if token
        token.extend_expiration!
        notice = "共有リンクの有効期限を延長しました。"
      else
        @recipe.recipe_share_tokens.create!
        notice = "共有リンクを新規発行しました。"
      end

      redirect_to recipe_path(@recipe), notice: notice
    end

    def destroy
      authorize @recipe, :manage_share_tokens?
      revoke_existing_tokens
      redirect_to recipe_path(@recipe), notice: "共有リンクを無効化しました。"
    end

    private

    def set_share_token
    @share_token = @recipe.recipe_share_tokens.find_by(id: params[:id])
    end

    # Uses update_all for efficiency; bypasses model callbacks and validations.
    def revoke_existing_tokens
    @recipe.recipe_share_tokens.active.update_all(revoked_at: Time.current)
    end
  end
end
