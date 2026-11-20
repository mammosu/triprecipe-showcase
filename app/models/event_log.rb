# EventLog
# プロダクト行動計測（分析用）のログモデルです。
# ユーザーの行動分析や機能利用状況の把握を主目的とします。
#
# 既存ログとの役割分担:
# - AuditLog: セキュリティ監査（誰がいつ何を変更したか）
# - RecipeShareAccessLog: シェアトークンのアクセス制限・有効期限管理のための低レベルログ
# - EventLog: 高レベルなユーザー行動イベント（閲覧、保存、Fork、共有など）
class EventLog < ApplicationRecord
  belongs_to :recipe
  belongs_to :actor, class_name: "User", optional: true

  validates :event_type, presence: true

  # Constants for event types
  EVENT_TYPES = %w[
    recipe_view
    recipe_save
    recipe_fork
    recipe_share
    collaborator_invite
    collaborator_accept
  ].freeze

  validates :event_type, inclusion: { in: EVENT_TYPES }
end
