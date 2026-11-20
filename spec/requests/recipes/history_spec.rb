require "rails_helper"

RSpec.describe "Recipes::History", type: :request do
  let(:owner) { User.create!(email: "history_owner@example.com", password: "password123", password_confirmation: "password123") }
  let(:recipe) { Recipe.create!(title: "HistoryPlan", user: owner, slug: "history-plan") }

  before do
    sign_in owner
  end

  it "shows audit logs and versions" do
    recipe.update!(title: "HistoryPlan v2")
    recipe.update!(public: false)

    get recipe_history_path(recipe)
    expect(response).to have_http_status(:success)
    expect(response.body).to include("履歴")
    expect(response.body).to include("内容の差分")
  end
end
