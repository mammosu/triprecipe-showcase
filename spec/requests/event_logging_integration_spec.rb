require 'rails_helper'

RSpec.describe "Event Logging Integration", type: :request do
  let(:user) { create(:user) }
  let(:recipe) { create(:recipe, user: user, public: true) }
  let(:other_user) { create(:user) }

  describe "Recipe View" do
    it "logs recipe_view on show" do
      sign_in other_user
      expect {
        get recipe_path(recipe)
      }.to change(EventLog, :count).by(1)

      log = EventLog.last
      expect(log.event_type).to eq("recipe_view")
      expect(log.recipe).to eq(recipe)
      expect(log.actor).to eq(other_user)
    end

    it "logs recipe_view for guest" do
      expect {
        get recipe_path(recipe)
      }.to change(EventLog, :count).by(1)

      log = EventLog.last
      expect(log.event_type).to eq("recipe_view")
      expect(log.actor).to be_nil
    end

    it "does not log matching duplicated request in same instance (simulated)" do
      # Note: typical request spec makes new controller instance.
      # To test idempotency per request, we can't easily do it in request spec without custom hacks.
      # But we can verify prefetch header.

      expect {
        get recipe_path(recipe), headers: { "Purpose" => "prefetch" }
      }.not_to change(EventLog, :count)
    end
  end

  describe "Recipe Save" do
    it "logs recipe_save on create" do
      sign_in other_user
      expect {
        post recipe_saved_recipe_path(recipe)
      }.to change(EventLog, :count).by(1)

      log = EventLog.last
      expect(log.event_type).to eq("recipe_save")
      expect(log.actor).to eq(other_user)
    end

    it "does not log if already saved" do
      create(:saved_recipe, user: other_user, recipe: recipe)
      sign_in other_user

      expect {
        post recipe_saved_recipe_path(recipe)
      }.not_to change(EventLog, :count)
    end
  end

  describe "Recipe Fork" do
    it "logs recipe_fork on fork" do
      sign_in other_user
      expect {
        post fork_recipe_path(recipe)
      }.to change(EventLog, :count).by(1)

      log = EventLog.last
      expect(log.event_type).to eq("recipe_fork")
      expect(log.actor).to eq(other_user)
      expect(log.metadata["source_recipe_id"]).to eq(recipe.id)
    end

    it "prevents duplicate logging on double submission (debounce)" do
      sign_in other_user
      post fork_recipe_path(recipe)
      expect(response).to redirect_to(Recipe.order(:created_at).last) # first success

      # Second request with same session (Rack::Test maintains session cookie jar)
      expect {
        post fork_recipe_path(recipe)
      }.not_to change(EventLog, :count)

      expect(response).to redirect_to(recipe_path(recipe))
      expect(flash[:alert]).to include("処理中")
    end
  end

  describe "Recipe Share" do
    let(:share_token) { create(:recipe_share_token, recipe: recipe) }

    it "logs recipe_share when accessed via token" do
      # Guest access
      expect {
        get recipe_path(recipe, share_token: share_token.token)
      }.to change(EventLog, :count).by(2) # view + share

      logs = EventLog.where(recipe: recipe).order(:created_at)
      share_log = logs.find_by(event_type: "recipe_share")

      expect(share_log).to be_present
      expect(share_log.metadata["share_token_id"]).to eq(share_token.id)
      expect(share_log.actor).to be_nil
    end
  end

  describe "Collaborator Invite" do
    it "logs collaborator_invite on create" do
      sign_in user

      expect {
        post recipe_collaborators_path(recipe), params: { recipe_collaborator: { invite_email: "invite@example.com" } }
      }.to change(EventLog, :count).by(1)

      log = EventLog.last
      expect(log.event_type).to eq("collaborator_invite")
      expect(log.metadata["target_email"]).to eq("invite@example.com")
    end
  end

  describe "Collaborator Accept" do
    let(:invitation) { create(:recipe_collaborator, recipe: recipe, invite_email: other_user.email) }

    it "logs collaborator_accept on accept" do
      sign_in other_user
      expect {
        post accept_collaborator_invitation_path(invitation.invitation_token)
      }.to change(EventLog, :count).by(1)

      log = EventLog.last
      expect(log.event_type).to eq("collaborator_accept")
      expect(log.actor).to eq(other_user)
      expect(log.metadata["collaborator_id"]).to eq(invitation.id)
    end

    it "does not log if already accepted" do
      invitation.accept! # Force accept state
      sign_in other_user

      expect {
        post accept_collaborator_invitation_path(invitation.invitation_token)
      }.not_to change(EventLog, :count)

      expect(response).to redirect_to(recipe_path(recipe))
    end
  end
end
