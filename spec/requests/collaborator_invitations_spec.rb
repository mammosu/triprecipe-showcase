require 'rails_helper'

RSpec.describe "CollaboratorInvitations", type: :request do
  let(:owner) { create(:user) }
  let(:invite_email) { 'invitee@example.com' }
  let(:recipe) { create(:recipe, user: owner) }

  before { sign_in owner }

  it 'allows invited user to accept invitation via token after registering' do
    post recipe_collaborators_path(recipe), params: { recipe_collaborator: { invite_email: invite_email, role: 'viewer' } }
    collab = recipe.reload.recipe_collaborators.find_by(invite_email: invite_email)
    expect(collab).to be_present

    # simulate registration of invited user
    invited_user = create(:user, email: invite_email)

    # sign in invited user and accept invitation
    sign_out owner
    sign_in invited_user

    get collaborator_invitation_path(collab.invitation_token)
    expect(response).to have_http_status(:ok)

    post accept_collaborator_invitation_path(collab.invitation_token)
    expect(response).to redirect_to(recipe_path(recipe))

    collab.reload
    expect(collab.accepted?).to be true
    expect(collab.user_id).to eq(invited_user.id)
  end
end
