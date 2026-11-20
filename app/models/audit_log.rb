class AuditLog < ApplicationRecord
  self.table_name = "audit_logs"

  ACTIONS = %w[create update destroy fork recipe_step.photos_added recipe_step.photo_removed].freeze

  belongs_to :user, optional: true, foreign_key: :whodunnit

  validates :item_type, :item_id, :action, presence: true
  validates :action, inclusion: { in: ACTIONS }
end
