require "rails_helper"

RSpec.describe "Google Analytics tag", type: :request do
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("GA_MEASUREMENT_ID").and_return(measurement_id)
  end

  context "with a measurement ID configured" do
    let(:measurement_id) { "G-TEST123456" }

    it "renders the gtag snippet with the configured ID" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("https://www.googletagmanager.com/gtag/js?id=#{measurement_id}")
      expect(response.body).to include("gtag('config', '#{measurement_id}')")
    end
  end

  context "without a measurement ID configured" do
    let(:measurement_id) { nil }

    it "omits the Google Analytics tags" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("googletagmanager.com/gtag/js", "gtag('config'")
    end
  end
end
