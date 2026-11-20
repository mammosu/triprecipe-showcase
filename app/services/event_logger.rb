class EventLogger
  class Error < StandardError; end

  # @param event_type [String]
  # @param recipe [Recipe]
  # @param actor [User, nil]
  # @param metadata [Hash]
  def self.log!(event_type:, recipe:, actor: nil, metadata: {})
    # Validation is handled by the model, but we can do a quick check or let the model fail.
    # We'll rely on ActiveRecord validation to raise RecordInvalid if event_type is invalid.

    EventLog.create!(
      event_type: event_type,
      recipe: recipe,
      actor: actor,
      metadata: metadata
    )
  rescue ActiveRecord::RecordInvalid => e
    # Log error but don't crash the app flow might be desired if we treat logging as best-effort.
    # However, requirements say "不正な event_type は例外を投げる or 無視（どちらかを明示）"
    # and implementation requirement says "log!".
    # Let's re-raise or let create! raise it, effectively throwing exception for invalid data.
    # But for safety in production, we might want to just log the error.
    # Requirement: "不正な event_type は例外を投げる or 無視"
    # Let's throw exception because "log!" implies bang method behavior.
    raise e
  end
end
