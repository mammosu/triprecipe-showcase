require "rails_helper"

RSpec.describe Recipe, type: :model do
  include ActionDispatch::TestProcess::FixtureFile

  let(:user) do
    User.create!(
      email: "spec-user@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  describe "validations" do
    it "is valid with default fixture-like attributes" do
      plan = described_class.new(
        title: "ミラノ2泊3日の旅",
        city_display: "ミラノ",
        days_count: 3,
        description: "家族向けのショートトリップ",
        public: true,
        user: user
      )

      expect(plan).to be_valid
    end

    it "requires a title" do
      plan = described_class.new(title: "", user: user)

      expect(plan).to be_invalid
      plan.validate
      expect(plan.errors.added?(:title, :blank)).to be(true)
    end

    it "limits title length" do
      plan = described_class.new(title: "a" * 101, user: user)

      expect(plan).to be_invalid
      plan.validate
      expect(plan.errors.added?(:title, :too_long, count: 100)).to be(true)
    end

    it "limits city_display length but allows blank" do
      expect(
        described_class.new(title: "ok", city_display: "a" * 101, user: user)
      ).to be_invalid

      expect(
        described_class.new(title: "ok", city_display: "", user: user)
      ).to be_valid
    end

    it "restricts days_count to 1..60 when present" do
      invalid_plan = described_class.new(title: "ok", days_count: 0, user: user)

      expect(invalid_plan).to be_invalid
      invalid_plan.validate
      expect(invalid_plan.errors.added?(:days_count, :greater_than_or_equal_to, value: 0, count: 1)).to be(true)

      valid_plan = described_class.new(title: "ok", days_count: 60, user: user)

      expect(valid_plan).to be_valid
    end

    it "rejects nil public flag" do
      plan = described_class.new(title: "ok", public: nil, user: user)

      expect(plan).to be_invalid
      plan.validate
      expect(plan.errors.added?(:public, :inclusion, value: nil)).to be(true)
    end

    it "requires a user" do
      plan = described_class.new(title: "ミラノ2泊3日の旅")

      expect(plan).to be_invalid
      expect(plan.errors[:user]).to include("must exist")
    end

    describe "cover_image" do
      it "accepts allowed image types" do
        plan = described_class.new(title: "画像付き", user: user)
        plan.cover_image.attach(fixture_file_upload("cover.png", "image/png"))

        expect(plan).to be_valid
      end

      it "rejects disallowed content types" do
        plan = described_class.new(title: "画像付き", user: user)
        plan.cover_image.attach(fixture_file_upload("not_image.txt", "text/plain"))

        expect(plan).to be_invalid
        expect(plan.errors[:cover_image]).to include("はPNG/JPEG/WEBP形式の画像を選択してください")
      end

      it "rejects files larger than 5MB" do
        plan = described_class.new(title: "画像付き", user: user)
        plan.cover_image.attach(fixture_file_upload("large.jpg", "image/jpeg"))

        expect(plan).to be_invalid
        expect(plan.errors[:cover_image]).to include("は5MB以下の画像を選択してください")
      end
    end
  end

  describe "defaults" do
    it "is public by default" do
      plan = described_class.new(title: "default", user: user)

      expect(plan.public).to be(true)
      plan.save!
      expect(plan.reload.public).to be(true)
    end
  end

  describe "slug generation" do
    it "creates human readable slug from title and city" do
      city = create(:city, :with_aliases, name_ja: "東京", slug: "tokyo", alias_values: [ "東京", "Tokyo" ])
      plan = described_class.create!(title: "Tokyo Trip", city: city, user: user)

      expect(plan.slug).to eq("tokyo-trip-tokyo")
      expect(plan.to_param).to eq("tokyo-trip-tokyo")
    end

    it "appends numeric suffix when duplicates occur" do
      city = create(:city, :with_aliases, name_ja: "京都", slug: "kyoto", alias_values: [ "京都", "Kyoto" ])
      first = described_class.create!(title: "Same Name", city: city, user: user)
      second = described_class.create!(title: "Same Name", city: city, user: user)

      expect(first.slug).to eq("same-name-kyoto")
      expect(second.slug).to eq("same-name-kyoto-2")
    end

    it "falls back to random slug when title and city are not ASCII friendly" do
      plan = described_class.create!(title: "京都の旅", city_display: "日本", user: user)

      expect(plan.slug).to match(/\Arc[a-z0-9]{6}\z/)
    end

    it "fetches records by slug" do
      plan = described_class.create!(title: "ID検索", city_display: "大阪", user: user)

      expect(described_class.fetch_by_slug!(plan.slug)).to eq(plan)
    end

    it "regenerates slug when title or city changes and stores history" do
      plan = described_class.create!(title: "Tokyo Trip", city_display: "Tokyo", user: user)
      old_slug = plan.slug

      plan.update!(title: "Kyoto Trip", city_display: "Kyoto")

      expect(plan.slug).to eq("kyoto-trip-kyoto")
      expect(plan.slug).not_to eq(old_slug)
      expect(plan.slug_aliases.pluck(:slug)).to include(old_slug)
    end

    it "fetches records by legacy slug aliases" do
      plan = described_class.create!(title: "Osaka Food", city_display: "Osaka", user: user)
      previous_slug = plan.slug

      plan.update!(title: "New Osaka Plan")

      expect(described_class.fetch_by_slug!(previous_slug)).to eq(plan)
    end
  end

  describe "persistence" do
    it "persists all key attributes when valid" do
      plan = described_class.create!(
        title: "ミラノ2泊3日の旅",
        city_display: "ミラノ",
        days_count: 3,
        description: "テスト用の旅程",
        public: true,
        user: user
      )

      plan.reload

      aggregate_failures do
        expect(plan.title).to eq("ミラノ2泊3日の旅")
        expect(plan.city_display).to eq("ミラノ")
        expect(plan.days_count).to eq(3)
        expect(plan.description).to eq("テスト用の旅程")
        expect(plan.public).to eq(true)
        expect(plan.user).to eq(user)
      end
    end
  end

  describe "scopes" do
    let(:other_user) do
      User.create!(
        email: "other@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
    end

    describe ".with_favorites_count" do
      let!(:plan1) { described_class.create!(title: "Plan 1", user: user, public: true) }
      let!(:plan2) { described_class.create!(title: "Plan 2", user: user, public: true) }

      before do
        SavedRecipe.create!(user: other_user, recipe: plan1)
        SavedRecipe.create!(user: user, recipe: plan1)
      end

      it "includes favorites_count attribute" do
        plans = described_class.with_favorites_count.order(:id)
        plan1_record = plans.find { |plan| plan.id == plan1.id }
        plan2_record = plans.find { |plan| plan.id == plan2.id }

        expect(plan1_record.favorites_count).to eq(2)
        expect(plan2_record.favorites_count).to eq(0)
      end
    end

    describe ".popular_plans" do
      let!(:public_plan1) { described_class.create!(title: "Public 1", user: user, public: true) }
      let!(:public_plan2) { described_class.create!(title: "Public 2", user: user, public: true) }
      let!(:private_plan) { described_class.create!(title: "Private", user: user, public: false) }

      before do
        # Create favorites for public plans within 30 days
        3.times do |i|
          temp_user = User.create!(
            email: "temp_user_#{i}@example.com",
            password: "password123",
            password_confirmation: "password123"
          )
          SavedRecipe.create!(user: temp_user, recipe: public_plan1)
        end

        SavedRecipe.create!(user: other_user, recipe: public_plan2)

        # Create favorite for private plan
        temp_user = User.create!(
          email: "private_temp@example.com",
          password: "password123",
          password_confirmation: "password123"
        )
        SavedRecipe.create!(user: temp_user, recipe: private_plan)
      end

      it "returns only public plans" do
        popular = described_class.popular_plans

        expect(popular).to include(public_plan1, public_plan2)
        expect(popular).not_to include(private_plan)
      end

      it "orders by favorite count descending" do
        popular = described_class.popular_plans

        expect(popular.first).to eq(public_plan1)
        expect(popular.first.favorites_count).to eq(3)
        expect(popular.last).to eq(public_plan2)
        expect(popular.last.favorites_count).to eq(1)
      end

      it "respects limit parameter" do
        # Create more plans
        3.times do |i|
          plan = described_class.create!(title: "Extra #{i}", user: user, public: true)
          SavedRecipe.create!(user: other_user, recipe: plan)
        end

        popular = described_class.popular_plans(limit: 2)

        expect(popular.length).to eq(2)
      end

      it "only includes favorites from last 30 days" do
        old_plan = described_class.create!(title: "Old Plan", user: user, public: true)

        # Create old favorite (simulate by manually setting created_at)
        old_favorite = SavedRecipe.create!(user: other_user, recipe: old_plan)
        old_favorite.update_column(:created_at, 31.days.ago)

        popular = described_class.popular_plans

        expect(popular).not_to include(old_plan)
      end
    end
  end
end
