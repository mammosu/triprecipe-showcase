require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#safe_return_path" do
    let(:fallback) { "/fallback" }

    it "returns fallback when param is blank" do
      expect(helper.safe_return_path(nil, fallback: fallback)).to eq(fallback)
      expect(helper.safe_return_path("", fallback: fallback)).to eq(fallback)
    end

    it "returns fallback for absolute URLs" do
      expect(helper.safe_return_path("https://example.com", fallback: fallback)).to eq(fallback)
      expect(helper.safe_return_path("http://example.com/path", fallback: fallback)).to eq(fallback)
    end

    it "returns fallback for scheme-relative URLs" do
      expect(helper.safe_return_path("//evil.com", fallback: fallback)).to eq(fallback)
      expect(helper.safe_return_path("//evil.com/path", fallback: fallback)).to eq(fallback)
    end

    it "returns fallback for paths without a leading slash" do
      expect(helper.safe_return_path("recipes/1", fallback: fallback)).to eq(fallback)
    end

    it "returns fallback for invalid URIs" do
      expect(helper.safe_return_path("http://[::1", fallback: fallback)).to eq(fallback)
    end

    it "returns the param for safe relative paths" do
      expect(helper.safe_return_path("/recipes/1", fallback: fallback)).to eq("/recipes/1")
      expect(helper.safe_return_path("/recipes?tab=diffs", fallback: fallback)).to eq("/recipes?tab=diffs")
      expect(helper.safe_return_path("/recipes#section", fallback: fallback)).to eq("/recipes#section")
    end
  end
end
