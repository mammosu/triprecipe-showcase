require "rails_helper"

RSpec.describe RecipeReportPolicy, type: :policy do
  let(:user) { create(:user) }
  let(:public_recipe) { create(:recipe, public: true) }
  let(:private_recipe) { create(:recipe, public: false) }

  it "allows signed-in users to report public recipes" do
    report = RecipeReport.new(recipe: public_recipe, user: user)
    policy = described_class.new(user, report)

    expect(policy.create?).to be true
  end

  it "denies guests" do
    report = RecipeReport.new(recipe: public_recipe, user: nil)
    policy = described_class.new(nil, report)

    expect(policy.create?).to be false
  end

  it "denies reports for private recipes" do
    report = RecipeReport.new(recipe: private_recipe, user: user)
    policy = described_class.new(user, report)

    expect(policy.create?).to be false
  end
end
