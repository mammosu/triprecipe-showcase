require "rails_helper"

RSpec.describe "Recipe fork", type: :system do
  before do
    driven_by(:rack_test)
  end

  let(:owner) { create(:user, email: "fork-owner-system@example.com") }
  let(:user) { create(:user, email: "fork-user-system@example.com") }

  let!(:recipe) do
    Recipe.create!(title: "公開レシピ", user: owner, public: true, slug: "public-fork-ui")
  end

  it "forks a public recipe from the show page" do
    sign_in_as(user)

    visit recipe_path(recipe)
    expect(page).to have_button("このレシピをベースに作る")

    click_button "このレシピをベースに作る"

    forked = Recipe.order(:created_at).last
    expect(page).to have_current_path(recipe_path(forked))
    expect(page).to have_content("コピー元")
    expect(page).to have_content("公開レシピ")
    expect(page).to have_content("非公開")
  end
end
