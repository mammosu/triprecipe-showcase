require "rails_helper"

RSpec.describe "Home FAQ", type: :request do
  it "renders faq page" do
    get faq_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("よくある質問")
  end

  it "renders link to faq page on home" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(faq_path)
    expect(response.body).to include("FAQページを見る")
  end
end
