require "rails_helper"

RSpec.describe "Recipes::Versions restore", type: :request do
  let(:owner) { User.create!(email: "owner_restore@example.com", password: "password123", password_confirmation: "password123") }
  let(:recipe) { Recipe.create!(title: "RestorePlan", user: owner, slug: "restore-plan") }

  before do
    sign_in owner
  end

  it "restores a previous version" do
    recipe.update!(title: "RestorePlan v2")
    version = recipe.versions.last

    expect {
      post restore_recipe_version_path(recipe, version)
      recipe.reload
    }.to change { recipe.title }.from("RestorePlan v2").to("RestorePlan")

    expect(response).to redirect_to(recipe_path(recipe))
    follow_redirect!
    expect(response.body).to include("バージョンを復元しました")
  end
end
