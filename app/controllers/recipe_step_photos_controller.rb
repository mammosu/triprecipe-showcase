class RecipeStepPhotosController < ApplicationController
  include RecipeScoped
  include ActionView::RecordIdentifier

  before_action :authenticate_user!
  before_action :set_recipe
  before_action :set_recipe_day
  before_action :set_recipe_step
  before_action :authorize_recipe_update

  def destroy
    attachment = @recipe_step.photos.attachments.find(params[:id])
    RecipeStepPhotosService.purge!(step: @recipe_step, attachment: attachment, actor: current_user)

    flash.now[:notice] = "写真を削除しました。"

    respond_to do |format|
      format.html { redirect_to recipe_path(@recipe), notice: "写真を削除しました。" }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(dom_id(attachment)),
          turbo_stream.replace(dom_id(@recipe_step, :errors),
                               partial: "shared/errors", locals: { object: @recipe_step }),
          turbo_stream.replace("flash-messages", partial: "shared/flash_messages_block")
        ]
      end
    end
  end

  private

  def set_recipe_day
    @recipe_day = @recipe.recipe_days.find(params[:day_id])
  end

  def set_recipe_step
    @recipe_step = @recipe_day.recipe_steps.with_attached_photos.find(params[:step_id])
  end

  def authorize_recipe_update
    authorize @recipe, :update?
  end
end
