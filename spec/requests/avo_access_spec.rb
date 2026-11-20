require "rails_helper"

RSpec.describe "Avo access", type: :request do
  describe "GET /avo" do
    it "redirects guests to sign in" do
      get "/avo"
      expect(response).to have_http_status(:found)
      expect(response.location).to include("/users/sign_in")
    end

    it "rejects non-admin users" do
      sign_in create(:user)

      get "/avo"

      expect(response).to have_http_status(:forbidden)
    end

    it "allows admin users" do
      sign_in create(:user, admin: true)

      get "/avo"

      follow_redirect! if response.status == 302
      expect(response).to have_http_status(:ok)
    end
  end
end
