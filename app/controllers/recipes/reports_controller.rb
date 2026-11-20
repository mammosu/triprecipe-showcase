class Recipes::ReportsController < ApplicationController
  include RecipeScoped

  before_action :authenticate_user!
  before_action :set_recipe

  def create
    authorize RecipeReport.new(recipe: @recipe, user: current_user)

    existing_report = RecipeReport.find_by(recipe: @recipe, user: current_user)
    if existing_report.present?
      redirect_to recipe_path(@recipe), alert: t("recipes.reports.flash.duplicate")
      return
    end

    @report = RecipeReport.new(recipe: @recipe, user: current_user)
    @report.assign_attributes(report_params)

    if @report.save
      redirect_to recipe_path(@recipe), notice: t("recipes.reports.flash.created")
    else
      redirect_to recipe_path(@recipe), alert: t("recipes.reports.flash.failed")
    end
  end

  private

  def report_params
    params.require(:recipe_report).permit(:reason, :comment)
  end
end
