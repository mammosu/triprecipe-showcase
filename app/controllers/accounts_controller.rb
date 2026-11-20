class AccountsController < ApplicationController
  before_action :authenticate_user!

  def show
    email = current_user.email.to_s.downcase
    by_user = RecipeCollaborator.pending.where(user_id: current_user.id)
    by_email = RecipeCollaborator.pending.where("LOWER(invite_email) = ?", email)

    @pending_invitations = by_user.or(by_email).includes(recipe: :user).order(invited_at: :desc)
    @active_collaborations = RecipeCollaborator
                               .accepted
                               .where("recipe_collaborators.user_id = :id OR LOWER(recipe_collaborators.invite_email) = :email", id: current_user.id, email:)
                               .includes(recipe: :user)
                               .order("recipes.updated_at DESC")
  end
end
