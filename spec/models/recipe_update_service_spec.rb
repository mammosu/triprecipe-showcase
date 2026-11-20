require "rails_helper"

RSpec.describe RecipeUpdateService, type: :model do
  let(:user) do
    User.create!(
      email: "update-service@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  it "updates recipe with valid params" do
    recipe = Recipe.create!(title: "Old", slug: "old", user: user)

    result = RecipeUpdateService.call(recipe, { title: "Updated" })

    expect(result[:success]).to be true
    expect(result[:recipe].title).to eq("Updated")
  end

  it "returns failure with invalid params" do
    recipe = Recipe.create!(title: "Old", slug: "old", user: user)

    result = RecipeUpdateService.call(recipe, { title: "" })

    expect(result[:success]).to be false
    # persisted value should remain unchanged
    expect(result[:recipe].reload.title).to eq("Old")
  end
end
