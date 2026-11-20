# コーディングエージェント用プロンプト
Sprint 1 / Phase 5 Fork MVP（TripRecipe）

あなたは Rails 8.1 / SQLite / Hotwire / Tailwind / Devise / Pundit / RSpec に精通した
シニアRailsエンジニアです。
docs/phases/phase5_fork_discovery.md と
docs/phases/phase5_sprint1_pr_tasks.md を参照しながら、
以下を実装してください。

## 前提
- リポジトリ: TripRecipe
- Recipe URL は slug のみ（数値IDは404）
- 認証: Devise
- 認可: Pundit
- DB: SQLite
- テスト: RSpec
- UI: Hotwire + Tailwind
- 既存設計を尊重すること

## 使用ツール
- context7
  - Rails 8 / Pundit / ActiveRecord の公式仕様確認
- serena
  - 既存コードの探索
  - Recipe / RecipeDay / RecipeStep / slug / policy / spec の把握

## 作業ルール
- 必ず新規ブランチで作業する
  - 例: `feature/phase5-fork-sprint1`
- Fork 処理は Service に閉じ込める
- すべて Pundit 経由で権限チェックする
- 既存仕様を壊さない

## Sprint 1 ゴール
- 公開レシピを fork（コピー）できる
- fork 後は自分の非公開レシピになる
- Day / Step の構造と順序が保持される
- recipes#show に Fork CTA が表示される
- attribution（元レシピ表示）がある
- RSpec で最低限の安全網がある

## 実装スコープ外（Sprint 1ではやらない）
- Step写真（ActiveStorage）の複製
- share token 経由の fork
- タグ / 通報 / 検索改善

## 実装タスク（順序厳守）

### 1. DB & Model
- migration: recipes に forked_from_recipe_id 追加
- Recipe 自己参照関連を追加
- slug 重複回避の仕組み確認（必要なら追加）

### 2. Pundit & Routes
- RecipePolicy#fork? を追加
- 公開レシピのみ fork 可
- POST /recipes/:id/fork を追加

### 3. Fork Service
- RecipeForkService を作成
- transaction で Recipe / Day / Step を複製
- visibility は private
- forked_from_recipe_id をセット
- slug をユニーク生成

### 4. Controller
- RecipesController#fork を実装
- authorize を必ず呼ぶ
- 成功時: 新レシピへ遷移
- 失敗時: flash + 元へ

### 5. UI
- recipes/show に CTA 追加
- policy(@recipe).fork? のみ表示
- コピー先で attribution 表示

### 6. RSpec
- service spec（件数・順序・slug）
- request spec（権限）
- system spec（UI導線）

## 出力（PR完了時にまとめること）
- 変更ファイル一覧
- Fork 処理の概要
- 追加したテストの要点
- 手動確認手順（UI操作）

## 受け入れ条件（DoD）
- 全テスト Green
- Fork は公開レシピのみ可能
- slug URL のみ使用
- Day / Step の順序が保持されている
- UI/UX が破綻していない
