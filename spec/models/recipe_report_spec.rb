require "rails_helper"

RSpec.describe RecipeReport, type: :model do
  describe "associations" do
    it "belongs to recipe" do
      association = described_class.reflect_on_association(:recipe)
      expect(association&.macro).to eq(:belongs_to)
    end

    it "belongs to user" do
      association = described_class.reflect_on_association(:user)
      expect(association&.macro).to eq(:belongs_to)
    end

    it "belongs to handled_by_user" do
      association = described_class.reflect_on_association(:handled_by_user)
      expect(association&.macro).to eq(:belongs_to)
      expect(association&.class_name).to eq("User")
    end
  end

  it "is valid with required attributes" do
    report = build(:recipe_report)
    expect(report).to be_valid
  end

  it "requires a reason" do
    report = build(:recipe_report, reason: nil)
    expect(report).to be_invalid
    expect(report.errors[:reason]).to be_present
  end

  it "requires a status" do
    report = build(:recipe_report, status: nil)
    expect(report).to be_invalid
    expect(report.errors[:status]).to be_present
  end
end
