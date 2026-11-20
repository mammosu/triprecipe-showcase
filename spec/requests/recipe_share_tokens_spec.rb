require "rails_helper"

RSpec.describe "RecipeShareTokens", type: :request do
  let!(:owner) do
    User.create!(
      email: "owner@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:other_user) do
    User.create!(
      email: "viewer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:recipe) do
    Recipe.create!(title: "共有したい旅", public: false, user: owner)
  end

  describe "POST /recipes/:recipe_id/recipe_share_tokens" do
    it "allows owners to create a share token" do
      sign_in owner

      expect do
        post recipe_share_tokens_path(recipe)
      end.to change(RecipeShareToken, :count).by(1)

      expect(response).to redirect_to(recipe_path(recipe))
    end

    it "prevents non-owners from creating share tokens" do
      sign_in other_user

      expect do
        post recipe_share_tokens_path(recipe)
      end.not_to change(RecipeShareToken, :count)

      expect(response).to redirect_to(recipes_path)
    end
  end

  describe "DELETE /recipes/:recipe_id/recipe_share_tokens/:id" do
    it "revokes active share tokens" do
      sign_in owner
      post recipe_share_tokens_path(recipe)
      share_token = recipe.recipe_share_tokens.last

      delete recipe_share_token_path(recipe, share_token)

      expect(response).to redirect_to(recipe_path(recipe))
      expect(share_token.reload.active?).to be(false)
    end
  end

  describe "POST /recipes/:recipe_id/recipe_share_tokens/:id/extend_lifespan" do
    it "extends the expiration when requested by owner" do
      sign_in owner
      post recipe_share_tokens_path(recipe)
      token = recipe.recipe_share_tokens.last
      original_expiration = token.expires_at

      post extend_lifespan_recipe_share_token_path(recipe, token)

      expect(response).to redirect_to(recipe_path(recipe))
      expect(token.reload.expires_at).to be > original_expiration
    end

    it "prevents non owners from extending" do
      sign_in owner
      post recipe_share_tokens_path(recipe)
      sign_out owner
      sign_in other_user

      expect do
        post extend_lifespan_recipe_share_token_path(recipe, recipe.recipe_share_tokens.last)
      end.not_to change { recipe.recipe_share_tokens.count }

      expect(response).to redirect_to(recipes_path)
    end
  end

  describe "GET /share/:token" do
    it "redirects to the slug URL with share token param when active" do
      sign_in owner
      post recipe_share_tokens_path(recipe)
      share_token = recipe.recipe_share_tokens.last
      sign_out owner

      get share_recipe_path(token: share_token.token)

      expect(response).to redirect_to(recipe_url(recipe, share_token: share_token.token))
    end

    it "redirects home when token is invalid" do
      get share_recipe_path(token: "invalid")

      expect(response).to redirect_to(root_path)
    end
  end
end
