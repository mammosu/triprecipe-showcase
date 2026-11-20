require "rails_helper"

RSpec.describe "Profiles", type: :request do
  include ActionDispatch::TestProcess::FixtureFile
  describe "GET /profile/edit" do
    it "redirects guests to sign in" do
      get edit_profile_path
      expect(response).to redirect_to new_user_session_path
    end

    it "renders edit for signed-in user" do
      user = create(:user)
      sign_in user

      get edit_profile_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("プロフィール編集")
    end
  end

  describe "PATCH /profile" do
    it "updates the current user profile" do
      user = create(:user)
      sign_in user

      patch profile_path, params: {
        user: {
          display_name: "旅好き太郎",
          username: "trip_taro",
          bio: "旅のメモをまとめています。"
        }
      }

      expect(response).to redirect_to edit_profile_path
      expect(user.reload.display_name).to eq("旅好き太郎")
      expect(user.username).to eq("trip_taro")
      expect(user.bio).to eq("旅のメモをまとめています。")
    end

    it "does not update another user" do
      user = create(:user)
      other_user = create(:user, display_name: "Other")
      sign_in user

      patch profile_path, params: { user: { display_name: "Hacked" } }

      expect(other_user.reload.display_name).to eq("Other")
    end

    it "attaches an avatar on profile update" do
      user = create(:user)
      sign_in user
      avatar_file = fixture_file_upload("cover.png", "image/png")

      expect do
        patch profile_path, params: {
          user: {
            display_name: "旅好き太郎",
            avatar: avatar_file
          }
        }
      end.to change { user.reload.avatar.attached? }.from(false).to(true)

      expect(response).to redirect_to edit_profile_path
      expect(user.avatar.filename.to_s).to eq("cover.png")
    end

    it "replaces an existing avatar with a new one" do
      user = create(:user)
      user.avatar.attach(fixture_file_upload("cover.png", "image/png"))
      sign_in user

      new_avatar = fixture_file_upload("cover.jpg", "image/jpeg")
      patch profile_path, params: {
        user: {
          avatar: new_avatar
        }
      }

      expect(response).to redirect_to edit_profile_path
      expect(user.reload.avatar.attached?).to be true
      expect(user.avatar.filename.to_s).to eq("cover.jpg")
    end

    context "with invalid data" do
      it "re-renders edit with unprocessable_entity when display_name is too long" do
        user = create(:user, display_name: "Original Name")
        sign_in user

        # Display name max length is 30 characters
        patch profile_path, params: {
          user: { display_name: "a" * 31 }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("プロフィール編集")
        expect(user.reload.display_name).to eq("Original Name")
      end

      it "re-renders edit with unprocessable_entity when username is too short" do
        user = create(:user, username: "valid_name")
        sign_in user

        # Username min length is 3 characters
        patch profile_path, params: {
          user: { username: "ab" }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("プロフィール編集")
        expect(user.reload.username).to eq("valid_name")
      end

      it "re-renders edit with unprocessable_entity when username is too long" do
        user = create(:user, username: "valid_name")
        sign_in user

        # Username max length is 20 characters
        patch profile_path, params: {
          user: { username: "a" * 21 }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("プロフィール編集")
        expect(user.reload.username).to eq("valid_name")
      end

      it "re-renders edit with unprocessable_entity when username has invalid format" do
        user = create(:user, username: "valid_name")
        sign_in user

        # Username only allows alphanumeric and underscore
        patch profile_path, params: {
          user: { username: "invalid-name" }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("プロフィール編集")
        expect(user.reload.username).to eq("valid_name")
      end

      it "re-renders edit with unprocessable_entity when bio is too long" do
        user = create(:user, bio: "Original bio")
        sign_in user

        # Bio max length is 160 characters
        patch profile_path, params: {
          user: { bio: "a" * 161 }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("プロフィール編集")
        expect(user.reload.bio).to eq("Original bio")
      end
    end
  end
end
