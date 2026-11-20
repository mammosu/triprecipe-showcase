require "rails_helper"

RSpec.describe RecipeForkService, type: :model do
  include ActiveJob::TestHelper
  let(:owner) { create(:user, email: "owner-fork@example.com") }
  let(:forker) { create(:user, email: "forker@example.com") }

  it "duplicates recipe days and steps with order preserved" do
    source = Recipe.create!(title: "Original", user: owner, public: true, slug: "original-trip")
    day1 = RecipeDay.create!(recipe: source, title: "Day 1", day_order: 1)
    day2 = RecipeDay.create!(recipe: source, title: "Day 2", day_order: 2)
    RecipeStep.create!(recipe_day: day1, title: "Step 1", starts_at: "09:00", position: 1, category: "activity")
    RecipeStep.create!(recipe_day: day1, title: "Step 2", starts_at: "11:00", position: 2, category: "food")
    RecipeStep.create!(recipe_day: day2, title: "Step 3", starts_at: "10:00", position: 1, category: "move")

    result = RecipeForkService.call(source, forker)

    expect(result[:success]).to be true
    forked = result[:recipe]
    expect(forked).to be_persisted
    expect(forked.user).to eq(forker)
    expect(forked.public).to be false
    expect(forked.forked_from_recipe).to eq(source)

    expect(forked.recipe_days.count).to eq(source.recipe_days.count)
    expect(forked.recipe_days.order(:day_order).pluck(:day_order)).to eq(source.recipe_days.order(:day_order).pluck(:day_order))

    source_days = source.recipe_days.order(:day_order)
    fork_days = forked.recipe_days.order(:day_order)
    source_days.zip(fork_days).each do |source_day, fork_day|
      expect(fork_day.recipe_steps.order(:position).pluck(:position))
        .to eq(source_day.recipe_steps.order(:position).pluck(:position))
    end
  end

  it "generates a unique slug for the fork" do
    source = Recipe.create!(title: "Sluggy", user: owner, public: true, slug: "sluggy")
    Recipe.create!(title: "Existing Copy", user: owner, public: true, slug: "sluggy-copy")

    result = RecipeForkService.call(source, forker)

    expect(result[:recipe].slug).to eq("sluggy-copy-2")
  end

  it "records a single fork audit log and version" do
    source = Recipe.create!(title: "Audit Fork", user: owner, public: true, slug: "audit-fork")
    RecipeDay.create!(recipe: source, title: "Day 1", day_order: 1)
    RecipeStep.create!(recipe_day: source.recipe_days.first, title: "Step 1", starts_at: "09:00", position: 1, category: "activity")

    perform_enqueued_jobs do
      RecipeForkService.call(source, forker)
    end

    forked = Recipe.order(:created_at).last
    expect(AuditLog.where(item_type: "Recipe", item_id: forked.id, action: "fork").count).to eq(1)
    expect(AuditLog.where(item_type: "RecipeDay", item_id: forked.recipe_days.pluck(:id)).count).to eq(0)
    expect(AuditLog.where(item_type: "RecipeStep", item_id: forked.recipe_steps.pluck(:id)).count).to eq(0)

    expect(PaperTrail::Version.where(item_type: "Recipe", item_id: forked.id, event: "fork").count).to eq(1)
    expect(PaperTrail::Version.where(item_type: "RecipeDay", item_id: forked.recipe_days.pluck(:id)).count).to eq(0)
    expect(PaperTrail::Version.where(item_type: "RecipeStep", item_id: forked.recipe_steps.pluck(:id)).count).to eq(0)
  end
end
