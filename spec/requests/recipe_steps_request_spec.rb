require "rails_helper"

RSpec.describe "RecipeSteps", type: :request do
  let(:user) { User.create!(email: "step-user@example.com", password: "password123", password_confirmation: "password123") }

  describe "POST /recipes/:recipe_id/days/:day_id/steps" do
    it "creates a step when authorized" do
      recipe = Recipe.create!(title: "PlanSteps", user: user, slug: "plan-steps")
      day = recipe.recipe_days.create!(title: "Day A", day_order: 1)
      sign_in user

      params = { recipe_step: { title: "Step 1", starts_at: Time.current } }

      expect { post recipe_day_steps_path(recipe, day), params: params }.to change(day.recipe_steps, :count).by(1)
      expect(response).to have_http_status(:found)
    end

    it "forbids creation by non-collaborator" do
      recipe = Recipe.create!(title: "PlanSteps2", user: user, slug: "plan-steps2")
      day = recipe.recipe_days.create!(title: "Day B", day_order: 1)
      other = User.create!(email: "otherstep@example.com", password: "password123", password_confirmation: "password123")
      sign_in other

      post recipe_day_steps_path(recipe, day), params: { recipe_step: { title: "X", starts_at: Time.current } }
      expect(response).to have_http_status(:forbidden).or redirect_to(root_path).or redirect_to(recipes_path)
    end
  end

  describe "DELETE /recipes/:recipe_id/days/:day_id/steps/:id" do
    it "destroys a step when authorized" do
      recipe = Recipe.create!(title: "PlanSteps3", user: user, slug: "plan-steps3")
      day = recipe.recipe_days.create!(title: "Day C", day_order: 1)
      step = day.recipe_steps.create!(title: "S1", starts_at: Time.current)
      sign_in user

      expect { delete recipe_day_step_path(recipe, day, step) }.to change(day.recipe_steps, :count).by(-1)
      expect(response).to have_http_status(:found)
    end
  end
end
