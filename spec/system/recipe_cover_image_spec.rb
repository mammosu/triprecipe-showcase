require "rails_helper"

RSpec.describe "Recipe cover images", type: :system do
  include ActionDispatch::TestProcess::FixtureFile

  before do
    driven_by(:rack_test)
  end

  let(:user) do
    User.create!(
      email: "cover-user@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  it "shows cover images on the show and index pages" do
    sign_in_as(user)

    visit new_recipe_path
    fill_in "タイトル", with: "カバー画像付きレシピ"
    attach_file "カバー画像", Rails.root.join("spec/fixtures/files/cover.png")
    click_button "レシピを保存"

    expect(page).to have_css("img[alt='カバー画像付きレシピのカバー画像']")

    visit recipes_path
    expect(page).to have_css("img[alt='カバー画像付きレシピのカバー画像']")
  end

  it "removes a cover image when requested" do
    recipe = Recipe.create!(title: "削除テスト", user: user)
    recipe.cover_image.attach(fixture_file_upload("cover.jpg", "image/jpeg"))

    sign_in_as(user)
    visit edit_recipe_path(recipe)
    check "カバー画像を削除する"
    click_button "更新する"

    expect(page).not_to have_css("img[alt='削除テストのカバー画像']")
  end
end
