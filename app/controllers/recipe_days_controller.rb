class RecipeDaysController < ApplicationController
  include RecipeScoped

  before_action :authenticate_user!
  before_action :set_recipe
  before_action :set_recipe
  before_action :set_recipe_day, only: %i[edit update destroy]

  def new
    authorize @recipe, :update?
    @recipe_day = @recipe.recipe_days.build
  end

  def create
    authorize @recipe, :update?
    @recipe_day = @recipe.recipe_days.build(recipe_day_params)
    if current_user
      @recipe_day.last_edited_by = current_user
      @recipe_day.last_edited_by_email = current_user.email
    end

    if @recipe_day.save
      redirect_to recipe_path(@recipe), notice: "日程を追加しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @recipe, :update?
  end

  def update
    authorize @recipe, :update?
    @recipe_day.assign_attributes(recipe_day_params)
    if current_user
      @recipe_day.last_edited_by = current_user
      @recipe_day.last_edited_by_email = current_user.email
    end
    if @recipe_day.save
      redirect_to recipe_path(@recipe), notice: "日程を更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @recipe, :update?
    @recipe_day.destroy
    redirect_to recipe_path(@recipe), notice: "日程を削除しました。"
  end

  private

  def recipe_day_params
    params.require(:recipe_day).permit(:title, :notes, :starts_on, :day_order)
  end

  def set_recipe_day
    @recipe_day = @recipe.recipe_days.find(params[:id])
  end
end
