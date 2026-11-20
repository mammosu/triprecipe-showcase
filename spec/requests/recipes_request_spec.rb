require "rails_helper"

RSpec.describe "Recipes", type: :request do
  let(:user) do
    User.create!(email: "req-user@example.com", password: "password123", password_confirmation: "password123")
  end

  describe "POST /recipes" do
    it "creates recipe and redirects when signed in" do
      sign_in user

      params = { recipe: { title: "Request Create", city_display: "Tokyo", description: "desc", public: true } }

      expect {
        post recipes_path, params: params
      }.to change(Recipe, :count).by(1)

      expect(response).to have_http_status(:found)
      created = Recipe.order(:created_at).last
      expect(created.title).to eq("Request Create")
    end

    it "requires authentication" do
      params = { recipe: { title: "No Auth", slug: "no-auth" } }

      post recipes_path, params: params

      expect(response).to redirect_to(new_user_session_path)
    end

    it "filters tag_ids to active tags only" do
      sign_in user
      active_tag = create(:tag, key: "active")
      inactive_tag = create(:tag, key: "inactive", active: false)
      invalid_id = Tag.maximum(:id).to_i + 100

      params = {
        recipe: {
          title: "Tagged Recipe",
          city_display: "Tokyo",
          description: "desc",
          public: true,
          tag_ids: [ active_tag.id, inactive_tag.id, invalid_id ]
        }
      }

      post recipes_path, params: params

      created = Recipe.order(:created_at).last
      expect(created.tags).to contain_exactly(active_tag)
    end
  end

  describe "PATCH /recipes/:id" do
    it "updates recipe when authorized" do
      recipe = Recipe.create!(title: "Old Title", user: user, slug: "old-title")
      sign_in user

      patch recipe_path(recipe), params: { recipe: { title: "Updated Title" } }

      expect(response).to have_http_status(:found)
      expect(recipe.reload.title).to eq("Updated Title")
    end

    it "forbids update by other user" do
      other = User.create!(email: "other@example.com", password: "password123", password_confirmation: "password123")
      recipe = Recipe.create!(title: "Owner Only", user: user, slug: "owner-only")
      sign_in other

      patch recipe_path(recipe), params: { recipe: { title: "Hacked" } }

      expect(response).to have_http_status(:forbidden).or have_http_status(:found)
      expect(recipe.reload.title).to eq("Owner Only")
    end

    it "filters tag_ids to active tags only on update" do
      recipe = Recipe.create!(title: "Tagged", user: user, slug: "tagged")
      sign_in user
      active_tag = create(:tag, key: "active-update")
      inactive_tag = create(:tag, key: "inactive-update", active: false)
      invalid_id = Tag.maximum(:id).to_i + 100

      patch recipe_path(recipe), params: { recipe: { tag_ids: [ active_tag.id, inactive_tag.id, invalid_id ] } }

      expect(recipe.reload.tags).to contain_exactly(active_tag)
    end
  end
end
