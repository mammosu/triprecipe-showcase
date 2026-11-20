require "rails_helper"
require "cgi"

RSpec.describe "Recipes tag filtering", type: :request do
  let(:user) { create(:user) }
  let!(:family_tag) { create(:tag, key: "family", label_ja: "子連れ") }
  let!(:food_tag) { create(:tag, key: "food", label_ja: "グルメ") }

  let!(:family_recipe) do
    create(:recipe, user: user, title: "Family Plan").tap do |recipe|
      recipe.tags << family_tag
    end
  end
  let!(:food_recipe) do
    create(:recipe, user: user, title: "Food Plan").tap do |recipe|
      recipe.tags << food_tag
    end
  end
  let!(:both_recipe) do
    create(:recipe, user: user, title: "Family & Food").tap do |recipe|
      recipe.tags << [ family_tag, food_tag ]
    end
  end
  let!(:other_recipe) { create(:recipe, user: user, title: "Other Plan") }

  it "filters by single tag param" do
    get recipes_path, params: { tag: "family" }

    decoded_body = CGI.unescapeHTML(response.body)

    expect(decoded_body).to include(family_recipe.title)
    expect(decoded_body).to include(both_recipe.title)
    expect(decoded_body).not_to include(food_recipe.title)
    expect(decoded_body).not_to include(other_recipe.title)
  end

  it "filters by multiple tags with OR semantics" do
    get recipes_path, params: { tags: [ "family", "food" ] }

    decoded_body = CGI.unescapeHTML(response.body)

    expect(decoded_body).to include(family_recipe.title)
    expect(decoded_body).to include(food_recipe.title)
    expect(decoded_body).to include(both_recipe.title)
    expect(decoded_body).not_to include(other_recipe.title)
  end
end
