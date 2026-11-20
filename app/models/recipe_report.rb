class RecipeReport < ApplicationRecord
  REASONS = {
    spam: "spam",
    copyright: "copyright",
    hate: "hate",
    adult: "adult",
    other: "other"
  }.freeze

  STATUSES = {
    open: "open",
    reviewing: "reviewing",
    resolved: "resolved",
    dismissed: "dismissed"
  }.freeze

  belongs_to :recipe
  belongs_to :user
  belongs_to :handled_by_user, class_name: "User", optional: true

  enum :reason, REASONS, validate: true
  enum :status, STATUSES, validate: true
end
