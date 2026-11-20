require "rails_helper"
require "ostruct"

RSpec.describe RecipeShareTokenService, type: :model do
  let(:user) do
    User.create!(
      email: "share-service@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  it "loads active share token and logs access" do
    recipe = Recipe.create!(title: "Share Test", user: user, slug: "share-test")
    token = recipe.recipe_share_tokens.create!(token: "tkn123")

    fake_request = OpenStruct.new(remote_ip: "1.2.3.4", user_agent: "RSpec")

    result = RecipeShareTokenService.load_and_log(recipe, "tkn123", fake_request)

    expect(result[:share_token]).to eq(token)
    expect(result[:share_link_access_granted]).to be true
    # access log should be created
    expect(token.access_logs.count).to be >= 1
  end
end
