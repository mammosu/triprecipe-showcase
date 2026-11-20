require "rails_helper"

RSpec.describe "Recipe forks", type: :request do
  let(:owner) { create(:user, email: "fork-owner@example.com") }
  let(:user) { create(:user, email: "fork-user@example.com") }

  let!(:public_recipe) do
    Recipe.create!(title: "Public Fork", user: owner, public: true, slug: "public-fork")
  end

  let!(:private_recipe) do
    Recipe.create!(title: "Private Fork", user: owner, public: false, slug: "private-fork")
  end

  describe "POST /recipes/:id/fork" do
    it "requires authentication" do
      expect {
        post fork_recipe_path(public_recipe)
      }.not_to change(Recipe, :count)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "forbids for private recipes" do
      sign_in user

      expect {
        post fork_recipe_path(private_recipe)
      }.not_to change(Recipe, :count)

      expect(response).to redirect_to(recipes_path)
    end

    it "forks public recipes for signed-in users" do
      sign_in user

      expect {
        post fork_recipe_path(public_recipe)
      }.to change(Recipe, :count).by(1)

      forked = Recipe.order(:created_at).last
      expect(forked.forked_from_recipe_id).to eq(public_recipe.id)
      expect(forked.public).to be false
      expect(response).to redirect_to(recipe_path(forked))
    end

    it "handles fork failures with an alert" do
      sign_in user
      allow(RecipeForkService).to receive(:call).and_return({ success: false, recipe: nil })

      expect {
        post fork_recipe_path(public_recipe), headers: { "HTTP_REFERER" => recipe_path(public_recipe) }
      }.not_to change(Recipe, :count)

      expect(response).to redirect_to(recipe_path(public_recipe))
      expect(flash[:alert]).to eq("レシピのコピーに失敗しました。")
    end
  end
end
