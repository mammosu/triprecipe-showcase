# Changelog

すべての重要な変更はこのファイルに記録します。

## Unreleased

- なし

## 2025-12-16

- Pagy Tailwind ページネーション導入
  - `pagy` を導入し、Tailwind スタイルのページネーションコンポーネントを追加しました。
  - 実装ファイル: `app/views/shared/components/_pagy_nav_tailwind.html.erb`
  - 変更は PR `#57`（feature/pagy-tailwind）およびドキュメント用 PR `#58`（chore/docs/pagy）に含まれます。

- セキュリティ修正: 危険な `params.permit!` の使用を `request.query_parameters` に置換して Brakeman 警告を解消しました。

- テスト: 既存の RSpec を実行し、主要な回帰がないことを確認しました。
