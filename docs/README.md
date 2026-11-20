# TripRecipe ドキュメント

このリポジトリのドキュメントは以下の構成に整理されています。

- **design**: デザイン・UI 関連
  - [DESIGN_SYSTEM.md](design/DESIGN_SYSTEM.md)
  - [SCREENS_MVP.md](design/SCREENS_MVP.md)
  - [AGENTS_DESIGN_RULES.md](design/AGENTS_DESIGN_RULES.md)
- **architecture**: アーキテクチャ・設計ガイド
  - [PROJECT_OVERVIEW.md](architecture/PROJECT_OVERVIEW.md)
  - [pundit_migration_guide.md](architecture/pundit_migration_guide.md)
  - [REFACTOR_MCP.md](architecture/REFACTOR_MCP.md)
- **roadmap**: ロードマップ・変更履歴
  - [ROADMAP.md](roadmap/ROADMAP.md)
  - [CHANGELOG.md](roadmap/CHANGELOG.md)
  - [triprecipe_rename_roadmap.md](roadmap/triprecipe_rename_roadmap.md)
- **phases**: フェーズ別仕様・タスク
  - [phase1_recipe_day.md](phases/phase1_recipe_day.md)
  - [phase2_recipe_step.md](phases/phase2_recipe_step.md)
  - [phase3_favorite.md](phases/phase3_favorite.md)
  - [phase4_collaboration.md](phases/phase4_collaboration.md)
- **ops**: 運用ドキュメント
  - [SITEMAP.md](ops/SITEMAP.md)
- **issues**: 作業中の Issue ドキュメント（docs/issues/）
- **backup**: 旧ルートにあったドキュメントを一時退避（docs/backup/）

運用メモ
- ドキュメントを追加する場合は、該当カテゴリのサブフォルダへ配置してください。
- 旧ファイルを復元するには `git mv docs/backup/<file> docs/` を使ってください。
- 移行後は参照リンクが壊れていないか `grep -R "docs/" -n` 等で確認してください。

この README を更新したい場合は PR を作成してください。
