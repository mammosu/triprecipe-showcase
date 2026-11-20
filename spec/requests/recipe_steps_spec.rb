require "rails_helper"

RSpec.describe "RecipeSteps", type: :request do
  let!(:user) do
    User.create!(
      email: "timeline-user@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:other_user) do
    User.create!(
      email: "other-timeline@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:recipe) do
    Recipe.create!(title: "リスボン週末", city_display: "リスボン", description: "", public: true, user: user)
  end

  let!(:recipe_day) do
    RecipeDay.create!(title: "1日目", recipe: recipe, day_order: 1)
  end

  describe "POST /recipes/:recipe_id/recipe_days/:recipe_day_id/recipe_steps" do
    let(:params) do
      {
        recipe_step: {
          title: "朝食",
          starts_at: "08:00",
          ends_at: "09:00",
          category: "food"
        }
      }
    end

    it "creates an item for the owner" do
      sign_in user

      expect do
        post recipe_day_steps_path(recipe, recipe_day), params: params
      end.to change(RecipeStep, :count).by(1)

      expect(response).to redirect_to(recipe_path(recipe))
      follow_redirect!
      expect(response.body).to include("朝食")
    end

    it "rejects other users" do
      sign_in other_user

      post recipe_day_steps_path(recipe, recipe_day), params: params

      expect(response).to redirect_to(recipes_path)
    end
  end

  describe "PATCH /.../recipe_steps/:id" do
    let!(:recipe_step) do
      RecipeStep.create!(
        recipe_day: recipe_day,
        title: "朝食",
        starts_at: Time.zone.parse("08:00"),
        position: 1
      )
    end

    it "updates item for owner" do
      sign_in user

      patch recipe_day_step_path(recipe, recipe_day, recipe_step), params: {
        recipe_step: { title: "ブランチ" }
      }

      expect(response).to redirect_to(recipe_path(recipe))
      follow_redirect!
      expect(response.body).to include("ブランチ")
    end

    it "prevents other users" do
      sign_in other_user

      patch recipe_day_step_path(recipe, recipe_day, recipe_step), params: {
        recipe_step: { title: "NG" }
      }

      expect(response).to redirect_to(recipes_path)
      expect(recipe_step.reload.title).to eq("朝食")
    end
  end

  describe "DELETE /.../recipe_steps/:id" do
    let!(:recipe_step) do
      RecipeStep.create!(
        recipe_day: recipe_day,
        title: "朝食",
        starts_at: Time.zone.parse("08:00"),
        position: 1
      )
    end

    it "deletes item" do
      sign_in user

      expect do
        delete recipe_day_step_path(recipe, recipe_day, recipe_step)
      end.to change(RecipeStep, :count).by(-1)

      expect(response).to redirect_to(recipe_path(recipe))
    end
  end

  describe "POST move_up" do
    let!(:first_item) do
      RecipeStep.create!(recipe_day: recipe_day, title: "朝", starts_at: Time.zone.parse("08:00"), position: 1)
    end

    let!(:second_item) do
      RecipeStep.create!(recipe_day: recipe_day, title: "昼", starts_at: Time.zone.parse("12:00"), position: 2)
    end

    it "moves item up" do
      sign_in user

      post move_up_recipe_day_step_path(recipe, recipe_day, second_item)

      expect(response).to redirect_to(recipe_path(recipe))
      expect(second_item.reload.position).to eq(1)
      expect(first_item.reload.position).to eq(2)
    end
  end
end
