require "rails_helper"

RSpec.describe "Recipes::SavedRecipes", type: :request do
  let(:user) { User.create!(email: "saved-req@example.com", password: "password123", password_confirmation: "password123") }
  let(:recipe) { Recipe.create!(title: "Fav Plan", user: user, slug: "fav-plan-req") }

  before { sign_in user }

  describe "POST /recipes/:recipe_id/saved_recipe" do
    it "responds with turbo_stream when requested" do
      post recipe_saved_recipe_path(recipe), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('turbo-stream action="replace"')
      expect(response.body).to include("favorite_button_recipe_#{recipe.id}")
      expect(response.body).to include("favorite_button_mobile_recipe_#{recipe.id}")
    end

    it "redirects for HTML request (fallback)" do
      post recipe_saved_recipe_path(recipe)
      expect(response).to redirect_to(recipe_path(recipe))
    end
  end

  describe "DELETE /recipes/:recipe_id/saved_recipe" do
    before { user.saved_recipes.create!(recipe: recipe) }

    it "responds with turbo_stream when requested" do
      delete recipe_saved_recipe_path(recipe), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('turbo-stream action="replace"')
      expect(response.body).to include("favorite_button_recipe_#{recipe.id}")
      expect(response.body).to include("favorite_button_mobile_recipe_#{recipe.id}")
      expect(response.body).to include("お気に入りに追加")
    end

    it "redirects for HTML request (fallback)" do
      delete recipe_saved_recipe_path(recipe)
      expect(response).to redirect_to(recipe_path(recipe))
    end
  end
end
