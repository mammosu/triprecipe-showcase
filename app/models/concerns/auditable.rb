module Auditable
  extend ActiveSupport::Concern

  included do
    before_save :capture_attachment_changes_for_audit
    before_destroy :capture_attachment_changes_for_destroy
    after_commit :enqueue_audit_log_on_create, on: :create
    after_commit :enqueue_audit_log_on_update, on: :update
    after_commit :enqueue_audit_log_on_destroy, on: :destroy
  end

  private


  def enqueue_audit_log_on_create
    return if Current.audit_suppressed
    enqueue_audit_log("create", changes: previous_changes)
  end

  def enqueue_audit_log_on_update
    return if Current.audit_suppressed
    attachment_changes = @auditable_attachment_changes || {}
    enqueue_audit_log("update", changes: previous_changes, attachment_changes: attachment_changes)
    record_attachment_version(attachment_changes, action: "update")
  end

  def enqueue_audit_log_on_destroy
    return if Current.audit_suppressed
    attachment_changes = @auditable_attachment_changes || {}
    enqueue_audit_log("destroy", attachment_changes: attachment_changes)
    record_attachment_version(attachment_changes, action: "destroy")
  end

  def enqueue_audit_log(action, changes: {}, attachment_changes: {})
    metadata = build_metadata(changes, attachment_changes).merge(actor_email: Current.user&.email).compact

    # Avoid noisy duplicate update logs (e.g., touch/ActiveStorage side effects)
    return if action == "update" && metadata.except(:actor_email).blank?

    AuditLogJob.perform_later(
      item_type: self.class.name,
      item_id: id,
      action: action,
      whodunnit: Current.user&.id,
      metadata: metadata
    )
  rescue => e
    Rails.logger.warn("[Auditable] enqueue failed: #{e.class} #{e.message}")
  ensure
    @auditable_attachment_changes = nil if action == "update"
  end

  def build_metadata(changes, attachment_changes = {})
    return {} if changes.blank? && attachment_changes.blank?

    trimmed = changes.slice(*auditable_attributes)
    attribute_meta = trimmed.transform_values do |value|
      if value.is_a?(Array) && value.size == 2
        old_val, new_val = value
        { old: truncate_value(old_val), new: truncate_value(new_val) }
      else
        { new: truncate_value(value) }
      end
    end

    attribute_meta.merge(build_attachment_metadata(attachment_changes))
  end

  def build_attachment_metadata(attachment_changes)
    return {} if attachment_changes.blank?

    attachment_changes.each_with_object({}) do |(name, change), result|
      result[name] = attachment_change_payload(change)
    end
  end

  def attachment_change_payload(change)
    case change&.dig(:type)
    when :create
      { new: change[:filename] }
    when :destroy, :detach
      { old: "removed" }
    else
      { new: "changed" }
    end
  end

  def attachment_label(attachable)
    if attachable.respond_to?(:original_filename)
      attachable.original_filename
    elsif attachable.respond_to?(:filename)
      attachable.filename.to_s
    else
      attachable.to_s
    end
  end

  def auditable_attributes
    # 除外: 更新系のメタカラムやIDベースの追跡を避ける
    self.class.column_names - %w[created_at updated_at last_edited_by_id last_edited_by_email]
  end

  def truncate_value(value)
    string = value.is_a?(String) ? value : value.to_s
    string[0, 120]
  end

  def capture_attachment_changes_for_audit
    return unless respond_to?(:attachment_changes)

    normalized = normalize_attachment_changes(attachment_changes)
    @auditable_attachment_changes = (@auditable_attachment_changes || {}).merge(normalized)
  end

  def normalize_attachment_changes(changes)
    return {} if changes.blank?

    changes.to_h.each_with_object({}) do |(name, change), result|
      result[name] = case change
      when Hash
                       change.symbolize_keys
      when ActiveStorage::Attached::Changes::CreateOne
                       { type: :create, filename: attachment_label(change.attachable) }
      when defined?(ActiveStorage::Attached::Changes::DestroyOne) && ActiveStorage::Attached::Changes::DestroyOne && change.is_a?(ActiveStorage::Attached::Changes::DestroyOne)
                       { type: :destroy, filename: attachment_label(change.attachable) }
      when defined?(ActiveStorage::Attached::Changes::DetachOne) && ActiveStorage::Attached::Changes::DetachOne && change.is_a?(ActiveStorage::Attached::Changes::DetachOne)
                       { type: :detach }
      else
                       { type: :unknown }
      end
    end
  end

  def capture_attachment_changes_for_destroy
    normalized = {}

    if respond_to?(:attachment_changes)
      normalized.merge!(normalize_attachment_changes(attachment_changes))
    end

    if self.class.respond_to?(:reflect_on_all_attachments)
      self.class.reflect_on_all_attachments.each do |reflection|
        attachment = send(reflection.name)
        next unless attachment.respond_to?(:attached?) && attachment.attached?

        normalized[reflection.name.to_s] ||= { type: :destroy, filename: attachment.filename.to_s }
      end
    end

    @auditable_attachment_changes = (@auditable_attachment_changes || {}).merge(normalized)
  end

  def record_attachment_version(attachment_changes, action: "update")
    return if attachment_changes.blank?

    changes_hash = build_attachment_version_changes(attachment_changes)
    return if changes_hash.blank?

    serializer = PaperTrail.serializer
    version_klass = PaperTrail::Version

    version = version_klass
                        .where(item_type: self.class.name, item_id: id, event: action)
                        .order(created_at: :desc)
                        .first

    if version.present? && version.created_at >= 5.seconds.ago
      existing = version.object_changes.present? ? serializer.load(version.object_changes) : {}
      merged = existing.merge(changes_hash)
      version.update_column(:object_changes, serializer.dump(merged))
    else
      v = version_klass.create!(
        item_type: self.class.name,
        item_id: id,
        event: action,
        whodunnit: Current.user&.id&.to_s,
        actor_email: Current.user&.email,
        object_changes: serializer.dump(changes_hash)
      )
    end
  rescue => e
    Rails.logger.warn("[Auditable] version record failed: #{e.class} #{e.message}")
  end

  def build_attachment_version_changes(attachment_changes)
    attachment_changes.each_with_object({}) do |(name, change), result|
      diff = attachment_version_diff(change)
      result[name.to_s] = diff if diff.present?
    end
  end

  def attachment_version_diff(change)
    case change&.dig(:type)
    when :create
      [ nil, change[:filename] ]
    when :destroy, :detach
      [ change[:filename] || "removed", nil ]
    else
      nil
    end
  end
end
