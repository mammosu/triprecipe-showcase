# Coding Agent Design Reference Rules

Coding Agent は UI 実装時に以下のファイルを必ず参照すること。

- docs/architecture/PROJECT_OVERVIEW.md
- docs/design/SCREENS_MVP.md
- docs/design/DESIGN_SYSTEM.md

> **MCP遵守**: [AGENTS.md](../../AGENTS.md) の共通ルールに従い、各ドキュメントに着手する前に Serena MCP と context7 MCP のリソースを確認し、必要な情報を取得すること。

## Rules

1. すべての UI コンポーネント（Button, Input, Card, Tag, RecipeStep など）は
   docs/design/DESIGN_SYSTEM.md の仕様に準拠して実装すること。

2. 新しい UI 要素を提案する場合は、
   - docs/design/DESIGN_SYSTEM.md に既存の類似要素があるか確認する
   - 整合性を説明する
   - 必要であれば docs/design/DESIGN_SYSTEM.md の更新案を提示する

3. Tailwind CSS のクラスは docs/design/DESIGN_SYSTEM.md の記述をベースに構築すること。

4. Material Design や Bootstrap など、別のデザイン体系を混在させてはならない。

5. 共通コンポーネントは `app/views/shared/` などのディレクトリにまとめて配置し、
   再利用性を高めること。
