class RecipeStepsController < ApplicationController
  include RecipeScoped

  before_action :authenticate_user!
  before_action :set_recipe
  before_action :set_recipe_day
  before_action :set_recipe_step, only: %i[edit update destroy move_up move_down]

  def new
    authorize @recipe, :update?
    @recipe_step = @recipe_day.recipe_steps.build
  end

  def create
    authorize @recipe, :update?
    @recipe_step = @recipe_day.recipe_steps.build(recipe_step_params.except(:photos))
    if current_user
      @recipe_step.last_edited_by = current_user
      @recipe_step.last_edited_by_email = current_user.email
    end

    new_photos = photos_param_files
    validate_new_photos(@recipe_step, new_photos)

    if @recipe_step.errors.any?
      reset_flash_for_render
      render :new, status: :unprocessable_entity and return
    end

    if @recipe_step.save
      attached = RecipeStepPhotosService.attach!(step: @recipe_step, files: new_photos, actor: current_user)
      redirect_to recipe_path(@recipe), notice: "行動を追加しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @recipe, :update?
  end

  def update
    authorize @recipe, :update?
    new_photos = photos_param_files
    validate_new_photos(@recipe_step, new_photos)

    @recipe_step.assign_attributes(recipe_step_params.except(:photos))
    if current_user
      @recipe_step.last_edited_by = current_user
      @recipe_step.last_edited_by_email = current_user.email
    end
    if @recipe_step.errors.any?
      reset_flash_for_render
      render :edit, status: :unprocessable_entity and return
    end

    if @recipe_step.save
      attached = RecipeStepPhotosService.attach!(step: @recipe_step, files: new_photos, actor: current_user)
      redirect_to recipe_path(@recipe), notice: "行動を更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @recipe, :update?
    @recipe_step.destroy
    respond_to do |format|
      format.html { redirect_to recipe_path(@recipe), notice: "行動を削除しました。" }
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@recipe_step) }
    end
  end

  def move_up
    authorize @recipe, :update?
    @recipe_step.move_up!
    if current_user
      @recipe_step.update_columns(last_edited_by_id: current_user.id, last_edited_by_email: current_user.email)
    end
    respond_to do |format|
      format.html { redirect_to recipe_path(@recipe) }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          helpers.dom_id(@recipe_day, :steps_list),
          partial: "recipe_days/steps_list",
          locals: { day: @recipe_day, recipe: @recipe, highlight_step_id: @recipe_step.id }
        )
      end
    end
  end

  def move_down
    authorize @recipe, :update?
    @recipe_step.move_down!
    if current_user
      @recipe_step.update_columns(last_edited_by_id: current_user.id, last_edited_by_email: current_user.email)
    end
    respond_to do |format|
      format.html { redirect_to recipe_path(@recipe) }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          helpers.dom_id(@recipe_day, :steps_list),
          partial: "recipe_days/steps_list",
          locals: { day: @recipe_day, recipe: @recipe, highlight_step_id: @recipe_step.id }
        )
      end
    end
  end

  private

  def set_recipe_day
    @recipe_day = @recipe.recipe_days.find(params[:day_id])
  end

  def set_recipe_step
    @recipe_step = @recipe_day.recipe_steps.find(params[:id])
  end

  def recipe_step_params
    params.require(:recipe_step).permit(:title, :category, :starts_at, :ends_at, :notes, :position, photos: [])
  end

  def photos_param_files
    Array(params.dig(:recipe_step, :photos)).compact_blank
  end

  def attach_photos(step, files)
    return [] if files.blank?

    step.photos.attach(files)
  end

  def validate_new_photos(step, files)
    return if files.blank?

    total = step.photos.attachments.size + files.size
    if total > RecipeStep::MAX_PHOTOS_COUNT
      step.errors.add(:photos, "は最大#{RecipeStep::MAX_PHOTOS_COUNT}枚までアップロードできます")
    end

    files.each do |file|
      unless RecipeStep::PHOTO_CONTENT_TYPES.include?(file.content_type)
        step.errors.add(:photos, "はPNG/JPEG/WEBP形式の画像を選択してください")
      end

      if file.size && file.size > RecipeStep::MAX_PHOTO_SIZE
        step.errors.add(:photos, "は1枚あたり5MB以下にしてください")
      end
    end
  end

  def reset_flash_for_render
    flash.to_hash.keys.each { |k| flash.discard(k) }
    # 併せてエラー枠を再描画して空にするためのフック（Turbo利用時に流用予定）
  end
end
