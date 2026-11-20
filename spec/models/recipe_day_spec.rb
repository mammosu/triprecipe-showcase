require "rails_helper"

RSpec.describe RecipeDay, type: :model do
  let(:user) do
    User.create!(
      email: "travel-day-user@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let(:recipe) do
    Recipe.create!(
      title: "バルセロナ 3 日間",
      city_display: "バルセロナ",
      description: "テスト",
      public: true,
      user: user
    )
  end

  describe "validations" do
    it "is valid with default attributes" do
      day = described_class.new(title: "1日目", recipe: recipe, day_order: 1)

      expect(day).to be_valid
    end

    it "requires a title" do
      day = described_class.new(title: "", recipe: recipe, day_order: 1)

      expect(day).to be_invalid
      day.validate
      expect(day.errors.added?(:title, :blank)).to be(true)
    end

    it "limits notes length" do
      day = described_class.new(title: "1日目", recipe: recipe, day_order: 1, notes: "a" * 2001)

      expect(day).to be_invalid
      day.validate
      expect(day.errors.added?(:notes, :too_long, count: 2000)).to be(true)
    end

    it "requires unique day order per travel plan" do
      described_class.create!(title: "1日目", recipe: recipe, day_order: 1)
      duplicate = described_class.new(title: "duplicate", recipe: recipe, day_order: 1)

      expect(duplicate).to be_invalid
      duplicate.validate
      expect(duplicate.errors.added?(:day_order, :taken, value: 1)).to be(true)
    end
  end

  describe "callbacks" do
    it "assigns day_order automatically when missing" do
      described_class.create!(title: "1日目", recipe: recipe, day_order: 1)
      day = described_class.create!(title: "2日目", recipe: recipe)

      expect(day.day_order).to eq(2)
    end
  end
end
