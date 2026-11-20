require "rails_helper"

RSpec.describe RecipeShareAccessLog, type: :model do
  let(:user) do
    User.create!(
      email: "log-owner@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let(:recipe) { Recipe.create!(title: "ログテスト", user: user) }
  let(:share_token) { RecipeShareToken.create!(recipe: recipe) }

  it "requires accessed_at" do
    log = described_class.new(recipe_share_token: share_token)

    expect(log).not_to be_valid
    log.accessed_at = Time.current
    expect(log).to be_valid
  end
end
