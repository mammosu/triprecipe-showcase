require "rails_helper"

RSpec.describe AuditLogDailySummaryJob, type: :job do
  include ActiveJob::TestHelper

  it "enqueues summary mail for owner when logs exist" do
    owner = User.create!(email: "summary-owner@example.com", password: "password123", password_confirmation: "password123")
    recipe = Recipe.create!(title: "Summary Plan", user: owner, slug: "summary-plan")
    AuditLog.create!(item_type: "Recipe", item_id: recipe.id, action: "update", metadata: {}, created_at: Time.current)

    expect do
      perform_enqueued_jobs do
        described_class.perform_now(since: 2.hours.ago)
      end
    end.to change { ActionMailer::Base.deliveries.size }.by(1)
  end
end
