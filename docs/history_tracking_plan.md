# 変更履歴管理ロードマップ（PaperTrail 導入を見据えた計画・改訂版）

目的: 変更責任を早期に可視化しつつ、将来 PaperTrail を導入して差分/ロールバックを提供しても衝突しない設計にする。

## フェーズ1: 更新者トラッキング（最小実装）
- 対象: Recipe / RecipeDay / RecipeStep
- 追加カラム: `last_edited_by_id`（nullable, FK to users）、表示用に `last_edited_by_email` を併存
- 実装: 更新時に `current_user` をセットし、メールも保持。詳細画面に「最終更新者・日時」を表示。
- テスト: Model 更新時の `last_edited_by_id` 設定、画面表示。

## フェーズ2: イベントベース監査ログ（差分なし）
- テーブル: `audit_logs`（PaperTrail の命名と整合、必要に応じて人向け表示用に `activity_logs` を別で追加する選択肢も残す）
- カラム: item_type, item_id, action, whodunnit, metadata(jsonb), created_at
- インデックス: [:item_type, :item_id], :whodunnit, :created_at を必須で付与（クエリ性能確保）
- 記録タイミング: モデルの after_commit で ActiveJob 経由（非同期）に書き込み。コールバック内で DB を直接更新せず再帰を防ぐ。失敗しても例外を上げず握りつぶす／リトライ。
- metadata: 変更カラム名と旧/新の短縮値、関連ユーザー名など最小限。個人情報はマスキングまたは保存しない。
- UI: レシピ詳細に「履歴」タブを追加（閲覧権限: owner/admin）。この時点では差分表示なし。
- テスト: ログ生成、権限制御、履歴一覧表示、ジョブ実行。

## フェーズ3: 通知・運用性
- 日次まとめ通知（メール or in-app）を owner/admin 向けに送信。
- ログ保持ポリシー: デフォルト 90 日保持。ジョブで削除 or S3 アーカイブ。設定で日数を調整できるように。
- バックフィル: `last_edited_by_id` は nullable のまま追加。既存データは updated_at のみ利用し、ユーザー推定は「推定フラグ」を metadata に付けて限定的に行う。audit_logs の本格バックフィルは small-batch rake で段階的に。

## フェーズ4: PaperTrail 導入（差分・ロールバック）
- 対象フィールド: テキスト中心（Recipe.title/description/city_display/days_count/public、RecipeDay.title/notes/day_order/starts_on、RecipeStep.title/notes/category/starts_at/ends_at/position）に `has_paper_trail` を適用済み。
- UI統合: イベント一覧は `audit_logs`、差分は Versions 一覧/詳細（recipes/:id/versions）で表示。ロールバックは未実装。
- テスト: versions 生成を model spec で確認（paper_trail_spec）。差分リクエスト表示を versions_spec で確認。

## フェーズ5: 差分UI強化・復元
- 2版選択のフィールド別 diff 表示（長文テキストのみ、サニタイズ必須）。
- 必要に応じて「この版に戻す」を提供（owner/admin のみに限定）。

## フェーズ6: 拡張・最適化
- 非同期 diff 計算や大容量データ対応。
- 個人情報を含むフィールドのマスキング/削除ポリシーを強化。

## 設計上の留意点（PaperTrail 共存）
- `audit_logs` と PaperTrail の `versions` は別テーブル・別責務。イベント一覧は前者、詳細差分とロールバックは後者。
- コールバック競合防止: after_commit -> ActiveJob にオフロードし、例外でトランザクションを壊さない。
- 用語/カラムは PaperTrail に合わせる（item_type, item_id, action, whodunnit）。
- ローテーションを早期に決めて肥大を防ぐ。S3 アーカイブも選択肢。

## 優先実装順
1) フェーズ1（実装済）: `last_edited_by` で最終更新者を表示。  
2) フェーズ2（実装済）: 履歴一覧（audit_logs）、Auditable concern、非同期書き込み・インデックス。  
3) フェーズ3で通知と保持ポリシーを整備（運用負荷低減）。  
4) 後続スプリントで PaperTrail（フェーズ4）を導入し、既存履歴タブに diff/復元を統合。

## 進捗メモ
- 2025-12-19: フェーズ1完了。Recipe/RecipeDay/RecipeStep に `last_edited_by` を追加し、作成/更新/並び替えで編集者を記録。概要に最終更新者表示。リクエストスペック追加済み。
- 2025-12-19: フェーズ2 実装完了 → audit_logs テーブル・Auditable concern・AuditLogJob を追加し、create/update/destroy を after_commit で非同期記録。履歴一覧 UI を管理者/オーナー向けに追加。request spec で権限確認済み。
- 2025-12-19: フェーズ3 着手 → AuditLogDailySummaryJob（24h サマリ通知）、AuditLogPruneJob（保持日数デフォルト90日）を追加。通知テンプレートはテキストメールで実装。
- 2025-12-19: フェーズ4準備 → 履歴UIを部分テンプレート化（`_event`）し、今後の PaperTrail 差分表示を差し替えやすい構造にリファクタ。
- 2025-12-19: 表示改善 → auditログの item_id を非表示化し、モデル・属性ラベルを i18n で日本語化。actor_email など文字列メタも表示可能に。
- 2025-12-19: PaperTrail 導入 → v17.0.0 を導入し、versionsテーブルを作成。Recipe/Day/Step でバージョン履歴を保存開始（差分UIは後続）。
