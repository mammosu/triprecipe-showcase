require "rails_helper"

RSpec.describe AuditLogPruneJob, type: :job do
  it "deletes old logs" do
    AuditLog.create!(item_type: "Recipe", item_id: 1, action: "create", metadata: {}, created_at: 120.days.ago)
    AuditLog.create!(item_type: "Recipe", item_id: 1, action: "update", metadata: {}, created_at: Time.current)

    expect {
      described_class.perform_now(retention_days: 90)
    }.to change { AuditLog.count }.by(-1)
  end
end
