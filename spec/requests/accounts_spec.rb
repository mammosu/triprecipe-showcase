require "rails_helper"

RSpec.describe "Accounts", type: :request do
  describe "GET /account" do
    let(:user) { create(:user) }
    let(:recipe) { create(:recipe) }
    let!(:invitation) do
      create(:recipe_collaborator, recipe:, invite_email: user.email, user: nil, role: "editor")
    end
    let!(:active_collaboration) do
      create(:recipe_collaborator, recipe:, user:, role: "viewer", accepted_at: Time.current)
    end

    it "redirects guests to sign in" do
      get account_path
      expect(response).to redirect_to new_user_session_path
    end

    it "shows pending invitations for the signed-in user" do
      sign_in user

      get account_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(recipe.title)
      expect(response.body).to include("ロール")
      expect(response.body).to include(invitation.role_label)
      expect(response.body).to include(active_collaboration.recipe.title)
    end
  end
end
