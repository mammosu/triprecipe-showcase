require "rails_helper"

RSpec.describe City, type: :model do
  describe "schema" do
    it "does not have legacy aliases column" do
      expect(City.column_names).not_to include("aliases")
    end
  end

  describe ".normalize" do
    it "returns nil for blank strings" do
      expect(described_class.normalize(nil)).to be_nil
      expect(described_class.normalize("")).to be_nil
      expect(described_class.normalize("   ")).to be_nil
    end

    it "normalizes width, spaces, punctuation, and case" do
      expect(described_class.normalize(" TOKYO ")).to eq("tokyo")
      expect(described_class.normalize("ＴＯＫＹＯ")).to eq("tokyo")
      expect(described_class.normalize("東京(都)")).to eq("東京都")
    end
  end

  describe ".match_by_alias" do
    let!(:city) { create(:city, :with_aliases, slug: "tokyo", alias_values: [ "東京", "とうきょう", "Tokyo", "TOKYO", "東京都" ]) }

    it "returns the city regardless of case or script" do
      expect(described_class.match_by_alias("Tokyo")).to eq(city)
      expect(described_class.match_by_alias("TOKYO")).to eq(city)
      expect(described_class.match_by_alias("東京")).to eq(city)
    end

    it "returns nil when not found" do
      expect(described_class.match_by_alias("Osaka")).to be_nil
    end
  end

  describe ".autocomplete" do
    before do
      create(:city, :with_aliases, name_ja: "東京", name_en: "Tokyo", slug: "tokyo", alias_values: [ "東京", "Tokyo" ])
      create(:city, :with_aliases, name_ja: "大阪", name_en: "Osaka", slug: "osaka", alias_values: [ "大阪", "Osaka" ])
    end

    it "returns up to 10 matching cities" do
      results = described_class.autocomplete("to")

      expect(results.length).to be >= 1
      expect(results.first.display_name).to eq("東京")
    end

    it "matches by alias fragments" do
      sapporo = create(:city, :with_aliases, name_ja: "札幌", name_en: "Sapporo", slug: "sapporo", alias_values: [ "札幌", "Sapporo" ])

      results = described_class.autocomplete("sap")

      expect(results).to include(sapporo)
    end
  end

  describe "alias persistence" do
    it "creates aliases via nested attributes" do
      city = City.create!(
        name_ja: "東京",
        slug: "tokyo",
        city_aliases_attributes: [
          { raw_name: "東京", normalized_name: City.normalize("東京") },
          { raw_name: "Tokyo", normalized_name: City.normalize("Tokyo") }
        ]
      )

      expect(city.city_aliases.count).to eq(2)
      expect(city.city_aliases.pluck(:normalized_name)).to include("tokyo")
    end

    it "rejects duplicate normalized_name within a city" do
      city = City.new(
        name_ja: "東京",
        slug: "tokyo",
        city_aliases_attributes: [
          { raw_name: "Tokyo", normalized_name: City.normalize("Tokyo") },
          { raw_name: "TOKYO", normalized_name: City.normalize("TOKYO") }
        ]
      )

      expect(city).not_to be_valid
      expect(city.errors.full_messages.join).to include("aliases must be unique")
    end
  end
end
