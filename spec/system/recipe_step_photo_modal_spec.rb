require "rails_helper"

RSpec.describe "Recipe step photo modal", type: :system do
  include ActionDispatch::TestProcess::FixtureFile

  before do
    driven_by(:rack_test)
  end

  let(:user) do
    User.create!(email: "step-modal@example.com", password: "password123", password_confirmation: "password123")
  end

  let(:recipe) { Recipe.create!(title: "写真モーダル", user: user, city_display: "東京") }
  let(:day) { recipe.recipe_days.create!(title: "1日目", day_order: 1) }
  let(:step) do
    day.recipe_steps.create!(
      title: "朝食",
      category: "food",
      starts_at: Time.zone.parse("2025-01-01 08:00")
    )
  end

  it "opens and closes the photo modal from a step thumbnail" do
    step.photos.attach([
      fixture_file_upload("cover.jpg", "image/jpeg"),
      fixture_file_upload("cover.png", "image/png")
    ])

    sign_in_as(user)
    visit recipe_path(recipe)

    expect(page).to have_css("button[data-action='click->photo-modal#open'] img")
    expect(page).to have_css(
      "a[aria-label='写真を削除'][data-turbo-method='delete'][data-turbo-confirm='この写真を削除しますか？']",
      visible: :all
    )

    delete_links = all("a[aria-label='写真を削除']", visible: :all)
    expect(delete_links.size).to eq(2)
    expect(delete_links.map { |link| link[:href] }).to match_array([
      recipe_day_step_photo_path(recipe, day, step, step.photos.first),
      recipe_day_step_photo_path(recipe, day, step, step.photos.second)
    ])
    expect(page).to have_css("[data-photo-modal-target='modal']", visible: :all)
    expect(page).to have_css("[data-photo-modal-target='prevButton']", visible: :all)
    expect(page).to have_css("[data-photo-modal-target='nextButton']", visible: :all)
    expect(page).to have_css("[data-photo-modal-target='counter']", visible: :all)

    if Capybara.current_driver != :rack_test
      find("button[data-action='click->photo-modal#open']").click
      expect(page).to have_css("[data-photo-modal-target='modal']", visible: true)
      expect(page).to have_css("[data-photo-modal-target='counter']", text: "1 / 2")
      expect(page).to have_css("[data-photo-modal-target='prevButton'][disabled]")
      expect(page).to have_css("[data-photo-modal-target='nextButton']:not([disabled])")

      find("body").send_keys(:arrow_right)
      expect(page).to have_css("[data-photo-modal-target='counter']", text: "2 / 2")
      expect(page).to have_css("[data-photo-modal-target='nextButton'][disabled]")
      expect(page).to have_css("[data-photo-modal-target='prevButton']:not([disabled])")

      find("body").send_keys(:arrow_left)
      expect(page).to have_css("[data-photo-modal-target='counter']", text: "1 / 2")

      find("[data-photo-modal-target='closeButton']").click
      expect(page).to have_css("[data-photo-modal-target='modal']", visible: :hidden)

      find("button[data-action='click->photo-modal#open']").click
      expect(page).to have_css("[data-photo-modal-target='modal']", visible: true)

      find("body").send_keys(:escape)
      expect(page).to have_css("[data-photo-modal-target='modal']", visible: :hidden)
    end
  end
end
