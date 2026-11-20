require "rails_helper"

RSpec.describe Tag, type: :model do
  describe "validations" do
    it "requires a key" do
      tag = described_class.new(key: nil)

      expect(tag).to be_invalid
      tag.validate
      expect(tag.errors.added?(:key, :blank)).to be(true)
    end

    it "enforces unique keys" do
      create(:tag, key: "family")
      duplicate = described_class.new(key: "family")

      expect(duplicate).to be_invalid
    end
  end

  describe "associations" do
    it "connects recipes through recipe_tags" do
      user = create(:user)
      recipe = create(:recipe, user: user)
      tag = create(:tag)

      recipe.tags << tag

      expect(tag.recipes).to include(recipe)
    end
  end

  describe "scopes" do
    it "returns active tags ordered by position" do
      active_late = create(:tag, position: 2, active: true)
      active_early = create(:tag, position: 1, active: true)
      create(:tag, position: 0, active: false)

      expect(described_class.active).to eq([ active_early, active_late ])
    end
  end

  describe "#display_label" do
    it "uses label_ja when present" do
      tag = described_class.new(key: "family", label_ja: "子連れ")

      expect(tag.display_label).to eq("子連れ")
    end

    it "falls back to key when label_ja is blank" do
      tag = described_class.new(key: "family", label_ja: "")

      expect(tag.display_label).to eq("family")
    end
  end
end
