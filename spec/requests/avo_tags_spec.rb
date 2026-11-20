require "rails_helper"

RSpec.describe "Avo tags", type: :request do
  describe "GET /avo/resources/tags" do
    it "rejects non-admin users" do
      sign_in create(:user)

      get "/avo/resources/tags"

      expect(response).to have_http_status(:forbidden)
    end

    it "allows admin users" do
      sign_in create(:user, admin: true)
      create(:tag)

      get "/avo/resources/tags"

      follow_redirect! if response.status == 302
      expect(response).to have_http_status(:ok)
    end
  end
end
