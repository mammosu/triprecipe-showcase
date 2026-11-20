require "rails_helper"
require "nokogiri"

RSpec.describe "SavedRecipes", type: :request do
  let!(:user) do
    User.create!(
      email: "fav-user@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:other_user) do
    User.create!(
      email: "fav-other@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:public_plan) do
    Recipe.create!(title: "パリ散策", city_display: "パリ", description: "", public: true, user: other_user)
  end

  let!(:private_plan) do
    Recipe.create!(title: "秘密旅", city_display: "札幌", description: "", public: false, user: other_user)
  end

  describe "GET /favorites" do
    it "requires authentication" do
      get saved_recipes_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "lists favorite plans for the user" do
      SavedRecipe.create!(user: user, recipe: public_plan)
      sign_in user

      get saved_recipes_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("パリ散策")
    end

    it "hides favorites for private plans the user cannot access" do
      SavedRecipe.create!(user: user, recipe: public_plan)
      public_plan.update!(public: false)
      sign_in user

      get saved_recipes_path

      expect(response.body).not_to include("パリ散策")
    end

    it "orders favorites by saved_at descending" do
      another_plan = Recipe.create!(title: "ベルリンの旅", city_display: "ベルリン", description: "", public: true, user: other_user)
      SavedRecipe.create!(user: user, recipe: public_plan).update_column(:created_at, 2.days.ago)
      SavedRecipe.create!(user: user, recipe: another_plan)

      sign_in user

      get saved_recipes_path

      expect(response).to have_http_status(:ok)

      doc = Nokogiri::HTML(response.body)
      card_titles = doc.css("a .recipe_title").map { |node| node.text.strip }.reject(&:blank?)

      expect(card_titles).to eq([ "ベルリンの旅", "パリ散策" ])
    end
  end

  describe "POST /recipes/:recipe_id/favorite" do
    it "allows user to favorite a public plan" do
      sign_in user

      expect do
        post recipe_saved_recipe_path(public_plan)
      end.to change(SavedRecipe, :count).by(1)

      expect(response).to redirect_to(recipe_path(public_plan))
    end

    it "prevents favoriting a private plan the user does not own" do
      sign_in user

      post recipe_saved_recipe_path(private_plan)

      expect(response).to redirect_to(recipes_path)
      expect(SavedRecipe.where(user: user, recipe: private_plan)).to be_empty
    end
  end

  describe "DELETE /recipes/:recipe_id/favorite" do
    it "removes an existing favorite" do
      SavedRecipe.create!(user: user, recipe: public_plan)
      sign_in user

      expect do
        delete recipe_saved_recipe_path(public_plan)
      end.to change(SavedRecipe, :count).by(-1)

      expect(response).to redirect_to(recipe_path(public_plan))
    end

    it "allows removal even if the plan became private" do
      SavedRecipe.create!(user: user, recipe: public_plan)
      public_plan.update!(public: false)
      sign_in user

      expect do
        delete recipe_saved_recipe_path(public_plan)
      end.to change(SavedRecipe, :count).by(-1)

      expect(response).to redirect_to(saved_recipes_path)
    end
  end
end
