require 'rails_helper'

RSpec.describe RecipeShareToken, type: :model do
  let(:recipe) { Recipe.create!(title: "T", city_display: "C", user: User.create!(email: "a#{SecureRandom.hex}@example.com", password: "password")) }

  it 'sets a default token and expiration on create' do
    token = recipe.recipe_share_tokens.create!
    expect(token.token).to be_present
    expect(token.expires_at).to be_present
  end

  it 'active scope excludes expired or revoked tokens' do
    t1 = recipe.recipe_share_tokens.create!(expires_at: 1.day.ago)
    t2 = recipe.recipe_share_tokens.create!(revoked_at: Time.current)
    t3 = recipe.recipe_share_tokens.create!(expires_at: 1.day.from_now)

    expect(RecipeShareToken.active).to include(t3)
    expect(RecipeShareToken.active).not_to include(t1)
    expect(RecipeShareToken.active).not_to include(t2)
  end

  it 'extend_expiration! extends from future expiration when present' do
    t = recipe.recipe_share_tokens.create!(expires_at: 2.days.from_now)
    old = t.expires_at
    t.extend_expiration!(duration: 7.days)
    expect(t.reload.expires_at).to be > old
  end

  it 'extend_expiration! extends from now when expired' do
    t = recipe.recipe_share_tokens.create!(expires_at: 2.days.ago)
    t.extend_expiration!(duration: 5.days)
    expect(t.reload.expires_at).to be > Time.current
  end

  it 'revoke! marks token as revoked' do
    t = recipe.recipe_share_tokens.create!
    t.revoke!
    expect(t.reload.revoked_at).to be_present
    expect(t.active?).to be false
  end
end
require "rails_helper"

RSpec.describe RecipeShareToken, type: :model do
  let(:user) do
    User.create!(
      email: "share-owner@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let(:recipe) { Recipe.create!(title: "共有テスト", user: user) }

  describe "callbacks" do
    it "generates a unique token and default expiration" do
      token = described_class.create!(recipe: recipe)
      expected_expiration = RecipeShareToken::DEFAULT_TTL.from_now

      expect(token.token).to be_present
      expect(token.expires_at).to be_within(5.seconds).of(expected_expiration)
    end
  end

  describe "scopes" do
    it "returns only active tokens" do
      active = described_class.create!(recipe: recipe)
      expired = described_class.create!(recipe: recipe, expires_at: 1.day.ago)
      revoked = described_class.create!(recipe: recipe, revoked_at: Time.current)

      expect(described_class.active).to include(active)
      expect(described_class.active).not_to include(expired)
      expect(described_class.active).not_to include(revoked)
    end
  end

  describe "#extend_expiration!" do
    it "extends from current expiration when still active" do
      token = described_class.create!(recipe: recipe)
      current_expiration = token.expires_at

      token.extend_expiration!

      expect(token.reload.expires_at).to be > current_expiration
    end

    it "extends from now when already expired" do
      token = described_class.create!(recipe: recipe, expires_at: 1.day.ago)

      token.extend_expiration!

      expect(token.reload.expires_at).to be > Time.current
    end
  end
end
