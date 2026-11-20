class Current < ActiveSupport::CurrentAttributes
  attribute :user
  attribute :audit_suppressed
end
