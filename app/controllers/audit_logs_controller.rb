class AuditLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_recipe
  before_action :authorize_view!

  def index
    @audit_logs = AuditLog
                    .where(item_type: "Recipe", item_id: @recipe.id)
                    .or(AuditLog.where(item_type: "RecipeDay", item_id: @recipe.recipe_days.select(:id)))
                    .or(AuditLog.where(item_type: "RecipeStep", item_id: @recipe.recipe_steps.select(:id)))
                    .order(created_at: :desc)
                    .limit(100)
  end

  private

  def set_recipe
    @recipe = Recipe.includes(:recipe_days, :recipe_steps).find_by!(slug: params[:recipe_id])
  end

  def authorize_view!
    authorize @recipe, :manage_collaborators?
  end
end
