require "rails_helper"

RSpec.describe "RecipeSteps Turbo", type: :request do
  let(:user) { User.create!(email: "turbo-steps@example.com", password: "password123", password_confirmation: "password123") }
  let(:recipe) { Recipe.create!(title: "Turbo Plan", user: user, slug: "turbo-plan") }
  let(:day) { recipe.recipe_days.create!(title: "Day 1", day_order: 1) }
  let!(:step1) { day.recipe_steps.create!(title: "Step 1", position: 1, starts_at: Time.current) }
  let!(:step2) { day.recipe_steps.create!(title: "Step 2", position: 2, starts_at: Time.current) }

  before { sign_in user }

  describe "DELETE /recipes/:recipe_id/days/:day_id/steps/:id" do
    it "removes the step via Turbo Stream" do
      delete recipe_day_step_path(recipe, day, step1), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('turbo-stream action="remove"')
      expect(response.body).to include(step1.id.to_s)
    end
  end

  describe "POST /move_up" do
    it "replaces the list via Turbo Stream" do
      post move_up_recipe_day_step_path(recipe, day, step2), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('turbo-stream action="replace"')
      # Should target the list container
      expect(response.body).to include("steps_list_recipe_day_#{day.id}")
      # List should be reordered (Step 2 first)
      expect(step1.reload.position).to eq(2)
      expect(step2.reload.position).to eq(1)
    end
  end
end
