require "rails_helper"

RSpec.describe RecipeIndexService, type: :model do
  let(:user) do
    User.create!(
      email: "index-service@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  it "returns index vars for anonymous user" do
    Recipe.create!(title: "Public Plan", user: user, public: true, slug: "public-plan")

    vars = RecipeIndexService.call(nil)

    expect(vars[:public_recipes]).to respond_to(:to_a)
    expect(vars[:popular_recipes]).to respond_to(:to_a)
    expect(vars[:my_recipes]).to be_nil
  end

  it "returns index vars for signed-in user" do
    recipe = Recipe.create!(title: "My Plan", user: user, public: false, slug: "my-plan")

    vars = RecipeIndexService.call(user)

    expect(vars[:my_recipes]).to include(recipe)
  end
end
