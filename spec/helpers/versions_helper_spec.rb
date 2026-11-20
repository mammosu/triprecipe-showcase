require "rails_helper"

RSpec.describe VersionsHelper, type: :helper do
  describe "#version_event_label" do
    it "returns Japanese labels for known events" do
      expect(helper.version_event_label("update")).to eq("更新")
      expect(helper.version_event_label("create")).to eq("作成")
      expect(helper.version_event_label("destroy")).to eq("削除")
    end

    it "returns the event string for unknown events" do
      expect(helper.version_event_label("fork")).to eq("fork")
    end
  end

  describe "#format_version_value" do
    it "returns placeholder for nil or empty values" do
      expect(helper.format_version_value(nil)).to eq("（空）")
      expect(helper.format_version_value("")).to eq("（空）")
      expect(helper.format_version_value([])).to eq("（空）")
    end

    it "formats Time/Date/DateTime values using I18n.l" do
      time = Time.zone.parse("2026-01-15 10:00:00")
      allow(I18n).to receive(:l).with(time).and_return("2026/01/15 10:00")
      expect(helper.format_version_value(time)).to eq("2026/01/15 10:00")
    end

    it "joins array entries with comma after formatting" do
      expect(helper.format_version_value([ "foo", "bar" ])).to eq("foo, bar")
    end

    it "truncates long strings to 120 chars" do
      long_string = "a" * 130
      expect(helper.format_version_value(long_string).length).to be <= 123 # 120 + omission("...")
      expect(helper.format_version_value(long_string)).to end_with("...")
    end

    it "falls back to to_s when I18n.l raises" do
      time = Time.zone.parse("2026-01-15 10:00:00")
      allow(I18n).to receive(:l).and_raise(I18n::ArgumentError)
      expect(helper.format_version_value(time)).to eq(time.to_s)
    end
  end

  describe "#restorable_version?" do
    let(:version) { instance_double("Version", item_type: item_type, event: event, changeset: changeset) }

    context "when item_type is not Recipe" do
      let(:item_type) { "RecipeDay" }
      let(:event) { "update" }
      let(:changeset) { { "title" => [ "old", "new" ] } }

      it { expect(helper.restorable_version?(version)).to be false }
    end

    context "when event is not update" do
      let(:item_type) { "Recipe" }
      let(:event) { "create" }
      let(:changeset) { { "title" => [ "old", "new" ] } }

      it { expect(helper.restorable_version?(version)).to be false }
    end

    context "when changeset is blank" do
      let(:item_type) { "Recipe" }
      let(:event) { "update" }
      let(:changeset) { {} }

      it { expect(helper.restorable_version?(version)).to be false }
    end

    context "when changeset includes restorable attributes" do
      let(:item_type) { "Recipe" }
      let(:event) { "update" }
      let(:changeset) { { "title" => [ "old", "new" ], "city_display" => [ "A", "B" ] } }

      it { expect(helper.restorable_version?(version)).to be true }
    end

    context "when changeset excludes restorable attributes" do
      let(:item_type) { "Recipe" }
      let(:event) { "update" }
      let(:changeset) { { "other" => [ "old", "new" ] } }

      it { expect(helper.restorable_version?(version)).to be false }
    end
  end
end
