require "rails_helper"

RSpec.describe User, type: :model do
  include ActionDispatch::TestProcess::FixtureFile

  describe "validations" do
    it "allows display_name up to 30 characters" do
      user = build(:user, display_name: "a" * 30)
      expect(user).to be_valid
    end

    it "rejects display_name longer than 30 characters" do
      user = build(:user, display_name: "a" * 31)
      expect(user).not_to be_valid
      expect(user.errors[:display_name]).to be_present
    end

    it "allows bio up to 160 characters" do
      user = build(:user, bio: "a" * 160)
      expect(user).to be_valid
    end

    it "rejects bio longer than 160 characters" do
      user = build(:user, bio: "a" * 161)
      expect(user).not_to be_valid
      expect(user.errors[:bio]).to be_present
    end

    it "allows nil username" do
      user = build(:user, username: nil)
      expect(user).to be_valid
    end

    it "rejects username shorter than 3 characters" do
      user = build(:user, username: "ab")
      expect(user).not_to be_valid
      expect(user.errors[:username]).to be_present
    end

    it "allows username up to 20 characters" do
      user = build(:user, username: "a" * 20)
      expect(user).to be_valid
    end

    it "rejects username longer than 20 characters" do
      user = build(:user, username: "a" * 21)
      expect(user).not_to be_valid
      expect(user.errors[:username]).to be_present
    end

    it "rejects username with invalid characters" do
      user = build(:user, username: "ab-c")
      expect(user).not_to be_valid
      expect(user.errors[:username]).to be_present
    end

    it "enforces case-insensitive uniqueness for username" do
      create(:user, username: "Travel_1")
      user = build(:user, username: "travel_1")
      expect(user).not_to be_valid
      expect(user.errors[:username]).to be_present
    end

    describe "avatar" do
      it "accepts allowed image types" do
        user = build(:user)
        user.avatar.attach(fixture_file_upload("cover.png", "image/png"))

        expect(user).to be_valid
      end

      it "rejects disallowed content types" do
        user = build(:user)
        user.avatar.attach(fixture_file_upload("not_image.txt", "text/plain"))

        expect(user).to be_invalid
        expect(user.errors[:avatar]).to include("はPNG/JPEG/WEBP形式の画像を選択してください")
      end

      it "rejects files larger than 5MB" do
        user = build(:user)
        user.avatar.attach(fixture_file_upload("large.jpg", "image/jpeg"))

        expect(user).to be_invalid
        expect(user.errors[:avatar]).to include("は5MB以下の画像を選択してください")
      end
    end
  end

  describe "#profile_slug" do
    it "returns username when username is present" do
      user = create(:user, username: "travel_user")
      expect(user.profile_slug).to eq("travel_user")
    end

    it "returns user ID when username is nil" do
      user = create(:user, username: nil)
      expect(user.profile_slug).to eq(user.id.to_s)
    end
  end

  describe "username normalization" do
    it "normalizes empty string to nil" do
      user = build(:user, username: "")
      user.valid?
      expect(user.username).to be_nil
    end

    it "normalizes whitespace-only string to nil" do
      user = build(:user, username: "   ")
      user.valid?
      expect(user.username).to be_nil
    end

    it "preserves valid username" do
      user = build(:user, username: "valid_user")
      user.valid?
      expect(user.username).to eq("valid_user")
    end
  end
end
