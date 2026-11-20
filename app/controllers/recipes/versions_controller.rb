class Recipes::VersionsController < ApplicationController
  include RecipeScoped

  before_action :authenticate_user!
  before_action :set_recipe
  before_action :authorize_view!

  def index
    @versions = PaperTrail::Version
                  .where(item_type: "Recipe", item_id: @recipe.id)
                  .or(PaperTrail::Version.where(item_type: "RecipeDay", item_id: @recipe.recipe_days.select(:id)))
                  .or(PaperTrail::Version.where(item_type: "RecipeStep", item_id: @recipe.recipe_steps.select(:id)))
                  .order(created_at: :desc)
                  .limit(100)
  end

  def show
    @version = PaperTrail::Version.find(params[:id])
    authorize_version!
  end

  def restore
    @version = PaperTrail::Version.find(params[:id])
    authorize_version!

    unless @version.item_type == "Recipe"
      redirect_to recipe_versions_path(@recipe), alert: "このバージョンの復元には未対応です。"
      return
    end

    changes = @version.changeset || {}
    attrs = changes.slice("title", "description", "city_display", "days_count", "public").transform_values { |(old_val, _new_val)| old_val }.symbolize_keys
    if attrs.blank?
      redirect_to recipe_versions_path(@recipe), alert: "復元対象の差分がありません。"
      return
    end

    PaperTrail.request(whodunnit: current_user&.id) do
      @recipe.update!(attrs)
    end
    redirect_to recipe_path(@recipe), notice: "バージョンを復元しました。"
  rescue => e
    Rails.logger.error("[VersionsController] restore failed: #{e.class} #{e.message}")
    redirect_to recipe_versions_path(@recipe), alert: "復元に失敗しました。"
  end

  private

  def authorize_view!
    authorize @recipe, :manage_collaborators?
  end

  def authorize_version!
    unless @version.item_id == @recipe.id ||
           @recipe.recipe_days.exists?(id: @version.item_id) ||
           @recipe.recipe_steps.exists?(id: @version.item_id)
      raise Pundit::NotAuthorizedError
    end
  end

  def recipe_param_key
    :recipe_id
  end
end
