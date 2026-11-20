require "rails_helper"

RSpec.describe "Recipe city assignments" do
  let(:user) { create(:user) }
  let!(:tokyo) { create(:city, :with_aliases, name_ja: "東京", slug: "tokyo", alias_values: [ "東京", "Tokyo" ]) }

  it "persists association when city_id is provided" do
    recipe = Recipe.create!(title: "City Linked", user: user, city_id: tokyo.id, city_display: "TOKYO")

    expect(recipe.city).to eq(tokyo)
    expect(recipe.city_display).to eq("TOKYO")
  end

  it "keeps city nil when only free text is provided" do
    recipe = Recipe.create!(title: "Free Text", user: user, city_display: "未登録都市")

    expect(recipe.city).to be_nil
    expect(recipe.city_display).to eq("未登録都市")
  end
end
