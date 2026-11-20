require "rails_helper"

RSpec.describe "Recipe reports", type: :request do
  let(:user) { create(:user) }
  let(:public_recipe) { create(:recipe, public: true) }
  let(:private_recipe) { create(:recipe, public: false) }

  describe "POST /recipes/:id/report" do
    it "requires authentication" do
      expect {
        post recipe_report_path(public_recipe), params: { recipe_report: { reason: "spam" } }
      }.not_to change(RecipeReport, :count)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "forbids reports for private recipes" do
      sign_in user

      expect {
        post recipe_report_path(private_recipe), params: { recipe_report: { reason: "spam" } }
      }.not_to change(RecipeReport, :count)

      expect(response).to redirect_to(recipes_path)
    end

    it "blocks duplicate reports for the same user and recipe" do
      sign_in user

      expect {
        post recipe_report_path(public_recipe), params: { recipe_report: { reason: "spam", comment: "first" } }
      }.to change(RecipeReport, :count).by(1)

      expect {
        post recipe_report_path(public_recipe), params: { recipe_report: { reason: "other", comment: "second" } }
      }.not_to change(RecipeReport, :count)

      report = RecipeReport.find_by(recipe: public_recipe, user: user)
      expect(report.reason).to eq("spam")
      expect(report.comment).to eq("first")
      expect(flash[:alert]).to eq(I18n.t("recipes.reports.flash.duplicate"))
    end

    it "handles validation failures when reason is missing" do
      sign_in user

      expect {
        post recipe_report_path(public_recipe), params: { recipe_report: { reason: nil, comment: "no reason" } }
      }.not_to change(RecipeReport, :count)

      expect(response).to redirect_to(recipe_path(public_recipe))
      expect(flash[:alert]).to eq(I18n.t("recipes.reports.flash.failed"))
    end
  end
end
