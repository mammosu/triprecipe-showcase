require "rails_helper"

RSpec.describe "Recipe visibility", type: :request do
  let(:owner) { create(:user) }
  let(:collaborator) { create(:user) }
  let(:recipe) { create(:recipe, user: owner, public: false) }

  before do
    RecipeCollaborator.create!(recipe:, user: collaborator, role: :viewer)
  end

  it "lets collaborators view private recipes" do
    sign_in collaborator

    get recipe_path(recipe)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(recipe.title)
  end
end
