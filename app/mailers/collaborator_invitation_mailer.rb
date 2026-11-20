class CollaboratorInvitationMailer < ApplicationMailer
  def invite
    @collaborator = params.fetch(:collaborator)
    @recipe = @collaborator.recipe
    @invitation_url = collaborator_invitation_url(@collaborator.invitation_token)

    mail to: @collaborator.invite_email, subject: "#{@recipe.title} のコラボレーション招待" do |format|
      format.text { render plain: "#{@recipe.user.email} さんからレシピ \"#{@recipe.title}\" への招待を受け取りました。招待を承認するには以下のリンクを開いてください: #{@invitation_url}" }
    end
  end
end
