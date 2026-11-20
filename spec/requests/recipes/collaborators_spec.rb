require 'rails_helper'

RSpec.describe "Recipes::Collaborators", type: :request do
  let(:owner) { User.create!(email: "owner_#{SecureRandom.hex}@example.com", password: "password123", password_confirmation: "password123") }
let(:recipe) { Recipe.create!(title: "Test Recipe", city_display: "Tokyo", user: owner) }
  let(:other_user) { User.create!(email: "other_#{SecureRandom.hex}@example.com", password: "password123", password_confirmation: "password123") }
  let(:collaborator_user) { User.create!(email: "collab_#{SecureRandom.hex}@example.com", password: "password123", password_confirmation: "password123") }
  let!(:collaborator) { RecipeCollaborator.create!(recipe: recipe, user: collaborator_user, role: :viewer) }

  before do
    sign_in owner
  end

  describe "GET /recipes/:recipe_id/collaborators" do
    it "returns http success for owner" do
      get recipe_collaborators_path(recipe)
      expect(response).to have_http_status(:success)
    end

    it "denies access for non-collaborator" do
      sign_in other_user
      get recipe_collaborators_path(recipe)
      expect(response).to redirect_to(recipes_path)
    end
  end

  describe "POST /recipes/:recipe_id/collaborators" do
    context "with valid parameters" do
      it "creates a new collaborator" do
        expect {
          post recipe_collaborators_path(recipe), params: { recipe_collaborator: { user_id: other_user.id, role: "editor" } }
        }.to change(RecipeCollaborator, :count).by(1)

        expect(response).to redirect_to(recipe_collaborators_path(recipe))
        expect(flash[:notice]).to eq "コラボレーターを招待しました。"

        new_collaborator = RecipeCollaborator.last
        expect(new_collaborator.user).to eq(other_user)
        expect(new_collaborator.role).to eq("editor")
      end
    end

    context "with invalid user_id" do
      it "does not create a collaborator" do
        expect {
          post recipe_collaborators_path(recipe), params: { recipe_collaborator: { user_id: -1, role: "editor" } }
        }.not_to change(RecipeCollaborator, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with invalid params (model validation failure)" do
      it "does not create a collaborator if role is missing" do
         expect {
          post recipe_collaborators_path(recipe), params: { recipe_collaborator: { user_id: other_user.id, role: "" } }
        }.not_to change(RecipeCollaborator, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH /recipes/:recipe_id/collaborators/:id" do
    it "updates the collaborator role" do
      patch recipe_collaborator_path(recipe, collaborator), params: { recipe_collaborator: { role: "admin" } }
      collaborator.reload
      expect(collaborator.role).to eq("admin")
      expect(response).to redirect_to(recipe_collaborators_path(recipe))
    end
  end

  describe "DELETE /recipes/:recipe_id/collaborators/:id" do
    it "removes the collaborator" do
      expect {
        delete recipe_collaborator_path(recipe, collaborator)
      }.to change(RecipeCollaborator, :count).by(-1)

      expect(response).to redirect_to(recipe_collaborators_path(recipe))
    end
  end
end
