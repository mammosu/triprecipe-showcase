require "rails_helper"

RSpec.describe RecipeCreateService, type: :model do
  let(:user) do
    User.create!(
      email: "create-service@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  it "creates a recipe with valid params" do
    params = { title: "New Plan", slug: "new-plan" }

    result = RecipeCreateService.call(user, params)

    expect(result[:success]).to be true
    expect(result[:recipe]).to be_persisted
    expect(result[:recipe].title).to eq("New Plan")
  end

  it "returns failure with invalid params" do
    params = { title: "", slug: "" }

    result = RecipeCreateService.call(user, params)

    expect(result[:success]).to be false
    expect(result[:recipe]).not_to be_persisted
  end
end
