require "rails_helper"

RSpec.describe RecipeSlug, type: :model do
  let(:user) do
    User.create!(
      email: "slug-history@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  it "validates uniqueness per slug" do
    plan = Recipe.create!(title: "旧スラッグ", city_display: "京都", user: user)
    RecipeSlug.create!(recipe: plan, slug: "kyoto-trip")

    duplicate = RecipeSlug.new(recipe: plan, slug: "kyoto-trip")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:slug]).to be_present
  end
end
