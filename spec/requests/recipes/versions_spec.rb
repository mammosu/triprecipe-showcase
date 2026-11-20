require "rails_helper"

RSpec.describe "Recipes::Versions", type: :request do
  let(:owner) { User.create!(email: "owner_v@example.com", password: "password123", password_confirmation: "password123") }
  let(:recipe) { Recipe.create!(title: "VPlan", user: owner, slug: "vplan") }

  before do
    sign_in owner
  end

  it "lists versions for recipe" do
    recipe.update!(title: "VPlan2")

    get recipe_versions_path(recipe)
    expect(response).to have_http_status(:success)
    expect(response.body).to include("変更履歴")
  end

  it "shows a version detail" do
    recipe.update!(title: "VPlan2")
    version = recipe.versions.last

    get recipe_version_path(recipe, version)
    expect(response).to have_http_status(:success)
    expect(response.body).to include("変更差分")
  end
end
