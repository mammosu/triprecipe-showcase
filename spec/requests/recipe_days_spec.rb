require "rails_helper"

RSpec.describe "RecipeDays", type: :request do
  let!(:user) do
    User.create!(
      email: "day-owner@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:other_user) do
    User.create!(
      email: "day-other@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:recipe) do
    Recipe.create!(
      title: "マドリード週末",
      city_display: "マドリード",
      description: "test",
      public: true,
      user: user
    )
  end

  describe "POST /recipes/:recipe_id/recipe_days" do
    let(:params) do
      {
        recipe_day: {
          title: "1日目",
          notes: "朝は美術館",
          starts_on: Date.today,
          day_order: 1
        }
      }
    end

    it "creates a travel day for the owner" do
      sign_in user

      expect do
        post recipe_days_path(recipe), params: params
      end.to change(RecipeDay, :count).by(1)

      expect(response).to redirect_to(recipe_path(recipe))
      follow_redirect!
      expect(response.body).to include("1日目")
    end

    it "rejects guests" do
      post recipe_days_path(recipe), params: params

      expect(response).to redirect_to(new_user_session_path)
    end

    it "rejects other users" do
      sign_in other_user

      post recipe_days_path(recipe), params: params

      expect(response).to redirect_to(recipes_path)
    end
  end

  describe "PATCH /recipes/:recipe_id/recipe_days/:id" do
    let!(:recipe_day) do
      RecipeDay.create!(title: "1日目", recipe: recipe, day_order: 1)
    end

    it "updates the travel day for the owner" do
      sign_in user

      patch recipe_day_path(recipe, recipe_day), params: {
        recipe_day: { title: "アップデート日程" }
      }

      expect(response).to redirect_to(recipe_path(recipe))
      follow_redirect!
      expect(response.body).to include("アップデート日程")
      expect(recipe_day.reload.title).to eq("アップデート日程")
    end

    it "prevents other users" do
      sign_in other_user

      patch recipe_day_path(recipe, recipe_day), params: {
        recipe_day: { title: "fail" }
      }

      expect(response).to redirect_to(recipes_path)
      expect(recipe_day.reload.title).to eq("1日目")
    end
  end

  describe "DELETE /recipes/:recipe_id/recipe_days/:id" do
    let!(:recipe_day) do
      RecipeDay.create!(title: "1日目", recipe: recipe, day_order: 1)
    end

    it "deletes the travel day for the owner" do
      sign_in user

      expect do
        delete recipe_day_path(recipe, recipe_day)
      end.to change(RecipeDay, :count).by(-1)

      expect(response).to redirect_to(recipe_path(recipe))
      follow_redirect!
      expect(response.body).not_to include("1日目")
    end
  end
end
