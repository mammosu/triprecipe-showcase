require "rails_helper"

RSpec.describe SavedRecipe, type: :model do
  let(:user) do
    User.create!(
      email: "favorite-user@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let(:plan_owner) do
    User.create!(
      email: "plan-owner@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let(:recipe) do
    Recipe.create!(title: "バルセロナ旅", city_display: "バルセロナ", description: "", public: true, user: plan_owner)
  end

  describe "validations" do
    it "allows a user to favorite a plan" do
      favorite = described_class.new(user: user, recipe: recipe)

      expect(favorite).to be_valid
    end

    it "prevents duplicate favorites" do
      described_class.create!(user: user, recipe: recipe)
      duplicate = described_class.new(user: user, recipe: recipe)

      expect(duplicate).to be_invalid
      duplicate.validate
      expect(duplicate.errors.added?(:user_id, :taken, value: user.id)).to be(true)
    end
  end
end
