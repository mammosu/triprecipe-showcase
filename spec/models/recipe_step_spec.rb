require "rails_helper"

RSpec.describe RecipeStep, type: :model do
  include ActionDispatch::TestProcess::FixtureFile
  let(:user) do
    User.create!(
      email: "timeline-owner@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let(:recipe) do
    Recipe.create!(title: "スペイン縦断", city_display: "マドリード", description: "", public: true, user: user)
  end

  let(:recipe_day) do
    RecipeDay.create!(title: "1日目", recipe: recipe, day_order: 1)
  end

  describe "validations" do
    it "is valid with default attributes" do
      item = described_class.new(
        recipe_day: recipe_day,
        title: "朝食",
        starts_at: Time.zone.parse("08:00"),
        ends_at: Time.zone.parse("09:00"),
        position: 1
      )

      expect(item).to be_valid
    end

    it "requires ends_at to be after starts_at" do
      item = described_class.new(
        recipe_day: recipe_day,
        title: "移動",
        starts_at: Time.zone.parse("10:00"),
        ends_at: Time.zone.parse("09:00"),
        position: 1
      )

      expect(item).to be_invalid
      item.validate
      expect(item.errors[:ends_at]).to be_present
    end

    it "rejects unknown categories" do
      item = described_class.new(
        recipe_day: recipe_day,
        title: "散策",
        starts_at: Time.zone.parse("12:00"),
        position: 1,
        category: "invalid"
      )

      expect(item).to be_invalid
      item.validate
      expect(item.errors[:category]).to be_present
    end
  end

  describe "callbacks" do
    it "auto assigns position when blank" do
      described_class.create!(recipe_day: recipe_day, title: "朝食", starts_at: Time.zone.parse("08:00"), position: 1)
      item = described_class.create!(recipe_day: recipe_day, title: "移動", starts_at: Time.zone.parse("09:00"))

      expect(item.position).to eq(2)
    end
  end

  describe "movement helpers" do
    it "moves an item up" do
      first = described_class.create!(recipe_day: recipe_day, title: "朝", starts_at: Time.zone.parse("08:00"), position: 1)
      second = described_class.create!(recipe_day: recipe_day, title: "昼", starts_at: Time.zone.parse("12:00"), position: 2)

      second.move_up!

      expect(second.reload.position).to eq(1)
      expect(first.reload.position).to eq(2)
    end
  end

  describe "photos validations" do
    let(:step) { described_class.new(recipe_day: recipe_day, title: "撮影", starts_at: Time.zone.parse("10:00")) }

    it "rejects too many photos" do
      3.times { step.photos.attach(fixture_file_upload("cover.png", "image/png")) }
      step.photos.attach(fixture_file_upload("cover.jpg", "image/jpeg"))

      expect(step).to be_invalid
      expect(step.errors[:photos]).to include("は最大3枚までアップロードできます")
    end

    it "rejects invalid content type" do
      step.photos.attach(fixture_file_upload("not_image.txt", "text/plain"))

      expect(step).to be_invalid
      expect(step.errors[:photos]).to include("はPNG/JPEG/WEBP形式の画像を選択してください")
    end

    it "rejects oversize file" do
      file = fixture_file_upload("cover.jpg", "image/jpeg")
      step.photos.attach(file)
      allow_any_instance_of(ActiveStorage::Blob).to receive(:byte_size).and_return(6.megabytes)

      expect(step).to be_invalid
      expect(step.errors[:photos]).to include("は1枚あたり5MB以下にしてください")
    end
  end
end
