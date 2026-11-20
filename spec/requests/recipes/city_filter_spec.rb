require "rails_helper"

RSpec.describe "Recipes city filtering", type: :request do
  let(:user) { create(:user) }
  let!(:tokyo) { create(:city, :with_aliases, name_ja: "東京", slug: "tokyo", alias_values: [ "東京", "Tokyo" ]) }
  let!(:osaka) { create(:city, :with_aliases, name_ja: "大阪", slug: "osaka", alias_values: [ "大阪", "Osaka" ]) }

  let!(:tokyo_plan) { create(:recipe, user: user, city: tokyo, city_display: "東京の旅") }
  let!(:osaka_plan) { create(:recipe, user: user, city: osaka, city_display: "大阪の旅") }
  let!(:other_plan) { create(:recipe, user: user, city: nil, city_display: "自由入力") }

  it "filters by city_id" do
    get recipes_path, params: { city_id: tokyo.id }

    expect(response.body).to include(tokyo_plan.title)
    expect(response.body).not_to include(osaka_plan.title)
  end

  it "allows selecting city_id = nil to represent others" do
    get recipes_path, params: { city_id: "none" }

    expect(response.body).to include(other_plan.title)
    expect(response.body).not_to include(tokyo_plan.title)
  end
end
