class CollaboratorInvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_invitation

  def show
    @recipe = @invitation.recipe
    @inviter = @recipe.user

    if @invitation.accepted?
      redirect_to recipe_path(@recipe), notice: "この招待は既に承認されています。"
    end
  end

  def accept
    if @invitation.accepted?
      redirect_to recipe_path(@invitation.recipe), notice: "この招待は既に承認されています。"
      return
    end

    # Associate to current_user if invitation was by email and user not set
    if @invitation.user.nil?
      @invitation.user = current_user
      @invitation.invite_email = nil
      @invitation.save!
    end

    if @invitation.accept!
      EventLogger.log!(
        event_type: "collaborator_accept",
        recipe: @invitation.recipe,
        actor: current_user,
        metadata: { collaborator_id: @invitation.id }
      )
      redirect_to recipe_path(@invitation.recipe), notice: "招待を承認しました。レシピにアクセスできるようになりました。"
    else
      redirect_to root_path, alert: "招待の承認に失敗しました。"
    end
  end

  def decline
    @invitation.destroy
    redirect_to root_path, notice: "招待を辞退しました。"
  end

  private

  def set_invitation
    @invitation = RecipeCollaborator.find_by!(invitation_token: params[:token])

    # Check if the current user is the invited user
    unless (@invitation.user_id.present? && @invitation.user_id == current_user.id) ||
           (@invitation.invite_email.present? && @invitation.invite_email.to_s.downcase.strip == current_user.email.to_s.downcase.strip)
      redirect_to root_path, alert: "この招待にアクセスする権限がありません。"
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "招待が見つかりませんでした。"
  end
end
