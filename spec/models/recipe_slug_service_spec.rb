require "rails_helper"

RSpec.describe RecipeSlugService, type: :model do
  let(:user) do
    User.create!(
      email: "slug-service@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  it "generates base slug when no conflict" do
    city = create(:city, :with_aliases, name_ja: "京都", slug: "kyoto", alias_values: [ "京都", "Kyoto" ])
    recipe = Recipe.create!(title: "Kyoto Trip", city: city, user: user)

    slug = RecipeSlugService.generate_unique_slug_for(recipe)

    expect(slug).to eq("Kyoto Trip-Kyoto".parameterize)
  end

  it "appends suffix when slug conflicts" do
    city = create(:city, :with_aliases, name_ja: "City", slug: "city", alias_values: [ "City" ])
    existing = Recipe.create!(title: "Same City", city: city, user: user, slug: "same-city-city")
    recipe = Recipe.new(title: "Same City", city: city, user: user)

    slug = RecipeSlugService.generate_unique_slug_for(recipe)

    expect(slug).to match(/-2$/)
    expect(slug.start_with?("same-city")).to be true
  end

  it "builds random slug when base blank" do
    recipe = Recipe.new(title: "", city_display: "", user: user)

    slug = RecipeSlugService.build_random_slug_for(recipe)

    expect(slug).to match(/^rc[a-z0-9]{6}$/)
  end
end
