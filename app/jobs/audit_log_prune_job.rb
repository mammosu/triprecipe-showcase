class AuditLogPruneJob < ApplicationJob
  queue_as :default

  def perform(retention_days: ENV.fetch("AUDIT_LOG_RETENTION_DAYS", 90).to_i)
    cutoff = retention_days.days.ago
    deleted = AuditLog.where("created_at < ?", cutoff).delete_all
    Rails.logger.info("[AuditLogPruneJob] deleted #{deleted} logs older than #{retention_days} days")
  rescue => e
    Rails.logger.warn("[AuditLogPruneJob] failed: #{e.class} #{e.message}")
  end
end
