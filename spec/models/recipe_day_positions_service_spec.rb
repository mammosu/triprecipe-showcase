require "rails_helper"

RSpec.describe RecipeDayPositionsService, type: :model do
  let(:user) do
    User.create!(
      email: "positions-service@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  it "reorders positions to be contiguous starting at 1" do
    recipe = Recipe.create!(title: "Positions Test", user: user)
    recipe_day = recipe.recipe_days.create!(title: "Day 1")

    # create steps with scrambled positions
    s1 = recipe_day.recipe_steps.create!(title: "A", starts_at: Time.current, position: 3)
    s2 = recipe_day.recipe_steps.create!(title: "B", starts_at: Time.current + 1.hour, position: 1)
    s3 = recipe_day.recipe_steps.create!(title: "C", starts_at: Time.current + 2.hours, position: 5)

    RecipeDayPositionsService.normalize_positions!(recipe_day)

    positions_after = recipe_day.recipe_steps.order(:position).pluck(:position)
    expect(positions_after).to eq([ 1, 2, 3 ])
  end
end
