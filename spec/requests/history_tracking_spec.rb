require "rails_helper"

RSpec.describe "History tracking", type: :request do
  let(:owner) { User.create!(email: "owner_ht@example.com", password: "password123", password_confirmation: "password123") }

  describe "Recipe last_edited_by" do
    let(:editor) { User.create!(email: "editor_ht@example.com", password: "password123", password_confirmation: "password123") }

    it "stores the user who updates the recipe" do
      recipe = Recipe.create!(title: "HT Plan", user: owner, slug: "ht-plan")
      RecipeCollaborator.create!(recipe: recipe, user: editor, role: :editor)
      sign_in editor

      patch recipe_path(recipe), params: { recipe: { title: "HT Plan Updated" } }

      expect(response).to have_http_status(:found)
      recipe.reload
      expect(recipe.last_edited_by).to eq(editor)
    end
  end

  describe "RecipeDay last_edited_by" do
    it "stores the user who updates the day" do
      recipe = Recipe.create!(title: "HT Day Plan", user: owner, slug: "ht-day-plan")
      day = recipe.recipe_days.create!(title: "Day 1", day_order: 1)
      sign_in owner

      patch recipe_day_path(recipe, day), params: { recipe_day: { title: "Day 1 updated" } }

      expect(response).to have_http_status(:found)
      expect(day.reload.last_edited_by).to eq(owner)
    end
  end

  describe "RecipeStep last_edited_by" do
    it "stores the user who updates the step" do
      recipe = Recipe.create!(title: "HT Step Plan", user: owner, slug: "ht-step-plan")
      day = recipe.recipe_days.create!(title: "Day 1", day_order: 1)
      step = day.recipe_steps.create!(title: "Step", starts_at: Time.zone.parse("09:00"))
      sign_in owner

      patch recipe_day_step_path(recipe, day, step), params: { recipe_step: { title: "Step updated" } }

      expect(response).to have_http_status(:found)
      expect(step.reload.last_edited_by).to eq(owner)
    end
  end
end
