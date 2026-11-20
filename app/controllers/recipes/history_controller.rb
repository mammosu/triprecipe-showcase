class Recipes::HistoryController < ApplicationController
  include RecipeScoped

  before_action :authenticate_user!
  before_action :set_recipe
  before_action :authorize_view!

  def index
    day_ids = @recipe.recipe_days.pluck(:id)
    step_ids = @recipe.recipe_steps.pluck(:id)

    @audit_logs = AuditLog.where(item_type: "Recipe", item_id: @recipe.id)
                          .or(AuditLog.where(item_type: "RecipeDay", item_id: day_ids))
                          .or(AuditLog.where(item_type: "RecipeStep", item_id: step_ids))
                          .order(created_at: :desc)
                          .limit(50)

    @versions = PaperTrail::Version
                .where(item_type: "Recipe", item_id: @recipe.id)
                .or(PaperTrail::Version.where(item_type: "RecipeDay", item_id: day_ids))
                .or(PaperTrail::Version.where(item_type: "RecipeStep", item_id: step_ids))
                .order(created_at: :desc)
                .limit(50)
  end

  private

  def authorize_view!
    authorize @recipe, :manage_collaborators?
  end

  def recipe_param_key
    :recipe_id
  end
end
