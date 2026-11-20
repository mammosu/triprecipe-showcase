require "rails_helper"

RSpec.describe "RecipeStep photos", type: :system do
  include ActionDispatch::TestProcess::FixtureFile

  before do
    driven_by(:rack_test)
  end

  let(:user) do
    User.create!(email: "step-photo@example.com", password: "password123", password_confirmation: "password123")
  end

  let(:recipe) { Recipe.create!(title: "写真付きステップ", user: user, city_display: "東京") }
  let(:day) { recipe.recipe_days.create!(title: "1日目", day_order: 1) }

  it "adds and removes photos", skip: "rack_test form submit flakiness; covered by request specs" do
    sign_in_as(user)

    visit new_recipe_day_step_path(recipe, day)
    fill_in "アクティビティ名", with: "朝食"
    fill_in "開始時刻", with: "08:00"
    find("select[name='recipe_step[category]'] option[value='food']").select_option
    attach_file "recipe_step_photos", [ Rails.root.join("spec/fixtures/files/cover.png"), Rails.root.join("spec/fixtures/files/cover.jpg") ]

    expect do
      first("button[type='submit']").click
    end.to change(RecipeStep, :count).by(1)

    step = RecipeStep.last
    expect(step.photos.count).to eq(2)

    # Delete via HTTP to avoid hover UI dependency
    page.driver.submit :delete, recipe_day_step_photo_path(recipe, day, step, step.photos.first), {}
    step.reload
    expect(step.photos.count).to eq(1)
  end
end
