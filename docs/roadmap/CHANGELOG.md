# Changelog

すべての重要な変更はこのファイルに記録します。

## Unreleased

- なし

## 2025-12-19

- 監査ログ改善: UI から item_id を非表示にし、モデル/属性ラベルを i18n で日本語化。`actor_email` など文字列メタも表示可能に。
- 更新者トラッキング: `last_edited_by_id`（FK）と表示用 `last_edited_by_email` を併存し、更新時に両方保存する運用に変更。
- 履歴表示: 監査ログ部分テンプレート化により diff UI への差し替えが容易に。
- PaperTrail 履歴: versions テーブルと履歴 UI（一覧/詳細）を追加し、Recipe の基本復元に対応。
- テスト: 監査関連の request/job/mailer specs すべてパス（既知の Rails 8.2 ルート keyword 警告のみ）。

## 2025-12-16

- Pagy Tailwind ページネーション導入
  - `pagy` を導入し、Tailwind スタイルのページネーションコンポーネントを追加しました。
  - 実装ファイル: `app/views/shared/components/_pagy_nav_tailwind.html.erb`
  - 変更は PR `#57`（feature/pagy-tailwind）およびドキュメント用 PR `#58`（chore/docs/pagy）に含まれます。

- セキュリティ修正: 危険な `params.permit!` の使用を `request.query_parameters` に置換して Brakeman 警告を解消しました。

- テスト: 既存の RSpec を実行し、主要な回帰がないことを確認しました。
