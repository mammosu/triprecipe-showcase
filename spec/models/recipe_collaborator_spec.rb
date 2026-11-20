require "rails_helper"

RSpec.describe RecipeCollaborator, type: :model do
  let(:user) { User.create!(email: "owner@example.com", password: "password123", password_confirmation: "password123") }
  let(:collaborator_user) { User.create!(email: "collaborator@example.com", password: "password123", password_confirmation: "password123") }
  let(:recipe) { Recipe.create!(title: "Test Recipe", city_display: "Tokyo", user: user) }

  describe "associations" do
    it "belongs to recipe" do
      expect(RecipeCollaborator.reflect_on_association(:recipe).macro).to eq(:belongs_to)
    end

    it "belongs to user" do
      expect(RecipeCollaborator.reflect_on_association(:user).macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "validates presence of role" do
      collaboration = RecipeCollaborator.new(recipe: recipe, user: collaborator_user)
      collaboration.role = nil

      expect(collaboration).not_to be_valid
      expect(collaboration.errors[:role]).to be_present
    end

    it "validates uniqueness of user_id scoped to recipe_id" do
      RecipeCollaborator.create!(recipe: recipe, user: collaborator_user, role: "viewer")
      duplicate = RecipeCollaborator.new(recipe: recipe, user: collaborator_user, role: "editor")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("is already a collaborator on this recipe")
    end

    it "prevents adding owner as collaborator" do
      collaboration = RecipeCollaborator.new(recipe: recipe, user: user, role: "viewer")

      expect(collaboration).not_to be_valid
      expect(collaboration.errors[:user]).to include("cannot be added as a collaborator (already the owner)")
    end
  end

  describe "enums" do
    it "defines role enum with correct values" do
      collaboration = RecipeCollaborator.new(recipe: recipe, user: collaborator_user)

      expect(collaboration).to respond_to(:viewer?)
      expect(collaboration).to respond_to(:editor?)
      expect(collaboration).to respond_to(:admin?)

      collaboration.role = "viewer"
      expect(collaboration.viewer?).to be true

      collaboration.role = "editor"
      expect(collaboration.editor?).to be true

      collaboration.role = "admin"
      expect(collaboration.admin?).to be true
    end
  end

  describe "scopes" do
    let!(:pending_collab) do
      RecipeCollaborator.create!(
        recipe: recipe,
        user: collaborator_user,
        role: "viewer",
        invited_at: Time.current
      )
    end

    let!(:accepted_collab) do
      another_user = User.create!(email: "another@example.com", password: "password123", password_confirmation: "password123")
      RecipeCollaborator.create!(
        recipe: recipe,
        user: another_user,
        role: "editor",
        invited_at: 1.day.ago,
        accepted_at: Time.current
      )
    end

    describe ".pending" do
      it "returns only pending collaborations" do
        expect(RecipeCollaborator.pending).to include(pending_collab)
        expect(RecipeCollaborator.pending).not_to include(accepted_collab)
      end
    end

    describe ".accepted" do
      it "returns only accepted collaborations" do
        expect(RecipeCollaborator.accepted).to include(accepted_collab)
        expect(RecipeCollaborator.accepted).not_to include(pending_collab)
      end
    end

    describe ".by_role" do
      it "filters by role" do
        expect(RecipeCollaborator.by_role("viewer")).to include(pending_collab)
        expect(RecipeCollaborator.by_role("viewer")).not_to include(accepted_collab)
      end
    end
  end

  describe "callbacks" do
    describe "invitation token generation" do
      it "generates invitation token before create" do
        collaboration = RecipeCollaborator.create!(recipe: recipe, user: collaborator_user, role: "viewer")

        expect(collaboration.invitation_token).to be_present
        expect(collaboration.invitation_token.length).to eq(32)
      end

      it "does not override existing invitation token" do
        custom_token = "custom_token_123"
        collaboration = RecipeCollaborator.create!(
          recipe: recipe,
          user: collaborator_user,
          role: "viewer",
          invitation_token: custom_token
        )

        expect(collaboration.invitation_token).to eq(custom_token)
      end
    end

    describe "invited_at timestamp" do
      it "sets invited_at before create" do
        collaboration = RecipeCollaborator.create!(recipe: recipe, user: collaborator_user, role: "viewer")

        expect(collaboration.invited_at).to be_present
        expect(collaboration.invited_at).to be_within(1.second).of(Time.current)
      end
    end
  end

  describe "#pending?" do
    it "returns true when invited but not accepted" do
      collaboration = RecipeCollaborator.create!(recipe: recipe, user: collaborator_user, role: "viewer")

      expect(collaboration.pending?).to be true
    end

    it "returns false when accepted" do
      collaboration = RecipeCollaborator.create!(recipe: recipe, user: collaborator_user, role: "viewer")
      collaboration.update!(accepted_at: Time.current)

      expect(collaboration.pending?).to be false
    end
  end

  describe "#accepted?" do
    it "returns false when not accepted" do
      collaboration = RecipeCollaborator.create!(recipe: recipe, user: collaborator_user, role: "viewer")

      expect(collaboration.accepted?).to be false
    end

    it "returns true when accepted" do
      collaboration = RecipeCollaborator.create!(recipe: recipe, user: collaborator_user, role: "viewer")
      collaboration.update!(accepted_at: Time.current)

      expect(collaboration.accepted?).to be true
    end
  end

  describe "#accept!" do
    it "sets accepted_at timestamp" do
      collaboration = RecipeCollaborator.create!(recipe: recipe, user: collaborator_user, role: "viewer")

      expect do
        collaboration.accept!
      end.to change { collaboration.accepted_at }.from(nil)

      expect(collaboration.accepted_at).to be_within(1.second).of(Time.current)
    end
  end
end
