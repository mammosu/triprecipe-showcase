require "rails_helper"

RSpec.describe "Cities", type: :request do
  describe "GET /cities" do
    let!(:tokyo) do
      create(:city,
        :with_aliases,
        name_ja: "東京",
        name_en: "Tokyo",
        country_code: "JP",
        slug: "tokyo",
        alias_values: [ "東京", "とうきょう", "Tokyo", "TOKYO", "東京都" ])
    end

    it "returns matches by normalized query" do
      get cities_path, params: { query: "tok" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.first.fetch("id")).to eq(tokyo.id)
      expect(json.first.fetch("display_name")).to eq("東京")
    end

    it "limits results to 10" do
      15.times do |i|
        create(:city, :with_aliases, name_ja: "都市#{i}", slug: "city-#{i}", alias_values: [ "都市#{i}" ])
      end

      get cities_path, params: { query: "都市" }

      json = JSON.parse(response.body)
      expect(json.size).to be <= 10
    end
  end
end
