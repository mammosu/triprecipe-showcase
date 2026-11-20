require 'rails_helper'

RSpec.describe 'CollaboratorInvitations authorization', type: :request do
  let(:owner) { create(:user) }
  let(:recipe) { create(:recipe, user: owner) }

  describe 'email-based invitation' do
    let(:invite_email) { 'victim@example.com' }
    let!(:collab) { recipe.recipe_collaborators.create!(invite_email: invite_email, role: 'viewer') }
    let(:attacker) { create(:user, email: 'attacker@example.com') }

    it 'prevents a different logged-in user from viewing and accepting the invitation' do
      sign_in attacker

      get collaborator_invitation_path(collab.invitation_token)
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include('この招待にアクセスする権限がありません。')

      post accept_collaborator_invitation_path(collab.invitation_token)
      expect(response).to redirect_to(root_path)

      collab.reload
      expect(collab.accepted?).to be false
    end
  end

  describe 'user-bound invitation' do
    let(:invited_user) { create(:user, email: 'invitee2@example.com') }
    let!(:collab) { recipe.recipe_collaborators.create!(user: invited_user, role: 'viewer') }
    let(:attacker) { create(:user, email: 'attacker2@example.com') }

    it 'prevents a different logged-in user from accepting a user-bound invitation' do
      sign_in attacker

      get collaborator_invitation_path(collab.invitation_token)
      expect(response).to redirect_to(root_path)

      post accept_collaborator_invitation_path(collab.invitation_token)
      expect(response).to redirect_to(root_path)

      collab.reload
      expect(collab.accepted?).to be false
    end
  end
end
