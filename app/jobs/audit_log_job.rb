class AuditLogJob < ApplicationJob
  queue_as :default

  def perform(item_type:, item_id:, action:, whodunnit:, metadata: {})
    AuditLog.create!(
      item_type: item_type,
      item_id: item_id,
      action: action,
      whodunnit: whodunnit,
      metadata: metadata.compact,
      created_at: Time.current
    )
  rescue => e
    Rails.logger.warn("[AuditLogJob] failed to create log: #{e.class} #{e.message}")
  end
end
