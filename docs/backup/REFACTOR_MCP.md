# Serena / context7 を活用したリファクタリング案

目的: Serena MCP と context7 MCP を活用して効率的にソース解析・設計見直しを行い、段階的に安全なリファクタリングを進めるためのチェックリストと実施方針をまとめる。

前提（合理的仮定）:
- 現行は Rails 8＋sqlite のアプリ構成。主要なドメインは `Recipe` / `RecipeDay` / `RecipeStep` である。
- Serena MCP と context7 MCP のシンボリック検索・ドキュメント取得機能を用いて、必要箇所だけを深堀りする。

優先度・実施順（推奨）:
1. リソース確認（Serena/context7） — 低リスク、短時間で環境把握
2. 静的解析・テストカバレッジ確認 — 潜在的問題の早期発見
3. モデル責務分離（Service/Interactor導入） — 中〜高優先
4. コントローラ簡素化・View コンポーネント化 — 中優先
5. クエリ最適化（N+1対策） — 中優先
6. ポリシー整備（Pundit 等） — 高優先（セキュリティ）
7. テスト整備とドキュメント化 — 常に並行

Serena MCP を使う場面（具体）:
- シンボリック検索で責務が集中するシンボルを特定する（例: `Recipe`/`RecipeDay` 内の大きなメソッド）
- 参照箇所の一覧を取得して、安全にメソッド抽出・移動ができるか確認する
- 変更前後に影響を受ける箇所（コントローラ／ビュー）を追跡する

context7 MCP を使う場面（具体）:
- 使用ライブラリやベストプラクティス（例: ActiveRecord の最適化パターン、Service Object のサンプル）の最新ドキュメント取得
- 既存の設計パターン（例: Rails + Hotwire）の実装例を参照して、ビュー/JS の分離方針を決める

リファクタリング対象と指標（短めに）:
- モデル
  - 目的: 単一責任原則に沿って薄くする
  - 対象例: [app/models/recipe_day.rb](../../app/models/recipe_day.rb), [app/models/recipe_step.rb](../../app/models/recipe_step.rb)
  - 作業例: 大きいロジックを `app/services/` に移す。バリデーション→concern／validatorへ分離。
  - DoD: 単体テストが追加され、変更前と同等の振る舞いを保持する。

- コントローラ
  - 目的: Fat Controller の解消（strong params + authorization 以外は薄く）
  - 対象例: [app/controllers/recipes_controller.rb](../../app/controllers/recipes_controller.rb)、[app/controllers/recipe_days_controller.rb](../../app/controllers/recipe_days_controller.rb)
  - 作業例: アクションロジックをサービスに委譲し、レスポンス・エラーハンドリングのみ残す。
  - DoD: 各アクションについて Request/System spec が存在する。

- View / Components
  - 目的: 再利用性とテスト容易性向上
  - 対象例: `app/views/recipes/*`, `app/views/recipes/_form.html.erb` 等
  - 作業例: 複雑な部分を ViewComponent（またはパーシャル）へ抽出。

- DB/クエリ最適化
  - 目的: N+1 を排除しレスポンスを改善
  - 検査対象: コントローラやジョブ内の ActiveRecord 呼び出し
  - 作業例: `includes` の追加・counter cache の導入・スコープ見直し

- Authorization（Pundit 等）
  - 目的: 権限ロジックの一元化、意図しないアクセス防止
  - 対象例: `app/policies/` 以下の未整備箇所
  - 作業例: ポリシーが十分にカバーしているかテストを追加。

安全な作業フロー（推奨）:
1. Serena で影響範囲を収集 → context7 で最適パターン調査
2. 小さな PR 単位（1機能／1ファイル群）で進める
3. 各 PR に対応する RSpec（Model/Request/System）を必須にする
4. CI (rspec) が通ることをマージ条件とする

推奨ファイルチェックリスト（最初に見るもの）:
- [app/models/recipe.rb](../../app/models/recipe.rb)
- [app/models/recipe_day.rb](../../app/models/recipe_day.rb)
- [app/models/recipe_step.rb](../../app/models/recipe_step.rb)
- [app/controllers/recipes_controller.rb](../../app/controllers/recipes_controller.rb)
- [app/controllers/recipe_days_controller.rb](../../app/controllers/recipe_days_controller.rb)
- [app/views/recipes/_form.html.erb](../../app/views/recipes/_form.html.erb)
- [app/policies/](../../app/policies/)
- [spec/](../../spec/) — 既存のテスト状況を確認

リスクと緩和策:
- 大規模なモデル移動は既存の参照破壊を生む → Serena で参照を網羅的に検索してから変更
- DBスキーマ変更はデプロイリスクが高い → マイグレーションは互換性を保つステップで実施（backfill／feature flag）

簡易工数目安（目安）:
- リソース確認・解析: 1–2日
- 小規模モデル分割（1モデル）: 0.5–1日
- コントローラ1個の薄型化 + テスト: 0.5–1日
- ViewComponent 抽出（1箇所）: 0.5–1日
- N+1 対策（調査＋修正）: 0.5–2日

次のアクション提案:
1. Serena MCP で `Recipe` 系のシンボル参照を収集する（初動）
2. context7 MCP で Service Object / ViewComponent のベストプラクティスを確認
3. 優先度の高い1つを選んで、ブランチを切り（`feature/refactor-...`）、PR として段階的に適用

参考: プロジェクトの設計・ガイドライン
- [AGENTS.md](../../AGENTS.md)
- [docs/DESIGN_SYSTEM.md](../design/DESIGN_SYSTEM.md)

もし望むなら、最初の Serena/context7 の検索と対象ファイル一覧作成をこちらで実行して、具体的な最初の PR を作成します。希望してください。
