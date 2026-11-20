class Recipes::CollaboratorsController < ApplicationController
  include RecipeScoped

  before_action :authenticate_user!
  before_action :set_recipe
  before_action :set_collaborator, only: %i[update destroy]
  before_action :authorize_management!

  def index
    @collaborators = @recipe.recipe_collaborators.includes(:user).order(created_at: :desc)
    @pending_collaborators = @collaborators.pending
    @accepted_collaborators = @collaborators.accepted
  end

  def create
    # Support two safe flows:
    # - explicit selection by `user_id` (handled safely here, not via mass-assignment)
    # - invite by email (new flow)
    user = nil
    if params.dig(:recipe_collaborator, :user_id).present?
      user = User.find_by(id: params.dig(:recipe_collaborator, :user_id))
    end

    invite_email = params.dig(:recipe_collaborator, :invite_email)&.to_s&.downcase&.strip
    user ||= User.find_by(email: invite_email) if invite_email.present?

    @collaborator = @recipe.recipe_collaborators.build(collaborator_params)
    if user
      @collaborator.user = user
      @collaborator.invite_email = nil
    else
      @collaborator.invite_email = invite_email
    end

    if @collaborator.save
      # Send invitation email when inviting by email (user not yet registered)
      if @collaborator.invite_email.present? && @collaborator.user.nil?
        CollaboratorInvitationMailer.with(collaborator: @collaborator).invite.deliver_later
      end

      EventLogger.log!(
        event_type: "collaborator_invite",
        recipe: @recipe,
        actor: current_user,
        metadata: {
          collaborator_id: @collaborator.id,
          target_user_id: @collaborator.user_id,
          target_email: @collaborator.invite_email
        }.compact
      )

      redirect_to recipe_collaborators_path(@recipe), notice: "コラボレーターを招待しました。"
    else
      @collaborators = @recipe.recipe_collaborators.includes(:user).order(created_at: :desc)
      @pending_collaborators = @collaborators.pending
      @accepted_collaborators = @collaborators.accepted
      render :index, status: :unprocessable_entity
    end
  end

  def update
    if @collaborator.update(collaborator_params.slice(:role))
      redirect_to recipe_collaborators_path(@recipe), notice: "ロールを更新しました。"
    else
      redirect_to recipe_collaborators_path(@recipe), alert: "ロールの更新に失敗しました。"
    end
  end

  def destroy
    @collaborator.destroy
    redirect_to recipe_collaborators_path(@recipe), notice: "コラボレーターを削除しました。"
  end

  private

  def collaborator_params
    # invite_email は静的解析でフラグが立てられる一括代入のリスクを回避するため明示的に処理される
    params.require(:recipe_collaborator).permit(:role)
  end

  def set_collaborator
    @collaborator = @recipe.recipe_collaborators.find(params[:id])
  end

  def authorize_management!
    authorize @recipe, :manage_collaborators?
  end

  def recipe_param_key
    :recipe_id
  end
end
