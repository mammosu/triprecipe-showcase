require "rails_helper"

RSpec.describe "RecipeDays", type: :request do
  let(:user) { User.create!(email: "day-user@example.com", password: "password123", password_confirmation: "password123") }

  describe "POST /recipes/:recipe_id/days" do
    it "creates a recipe day when authorized" do
      recipe = Recipe.create!(title: "Plan", user: user, slug: "plan")
      sign_in user

      params = { recipe_day: { title: "Day 1", notes: "notes" } }

      expect {
        post recipe_days_path(recipe), params: params
      }.to change(recipe.recipe_days, :count).by(1)

      expect(response).to have_http_status(:found)
    end

    it "forbids creation by another user" do
      recipe = Recipe.create!(title: "Plan2", user: user, slug: "plan2")
      other = User.create!(email: "other2@example.com", password: "password123", password_confirmation: "password123")
      sign_in other

      params = { recipe_day: { title: "Day X" } }
      post recipe_days_path(recipe), params: params

      expect(response).to have_http_status(:forbidden).or redirect_to(root_path).or redirect_to(recipes_path)
    end
  end

  describe "DELETE /recipes/:recipe_id/days/:id" do
    it "destroys a day when authorized" do
      recipe = Recipe.create!(title: "Plan3", user: user, slug: "plan3")
      day = recipe.recipe_days.create!(title: "D1", day_order: 1)
      sign_in user

      expect { delete recipe_day_path(recipe, day) }.to change(recipe.recipe_days, :count).by(-1)
      expect(response).to have_http_status(:found)
    end
  end
end
