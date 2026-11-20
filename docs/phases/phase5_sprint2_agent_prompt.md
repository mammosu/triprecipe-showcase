# コーディングエージェント用プロンプト
Sprint 2 / Phase 5 Tag導入 MVP（TripRecipe）

あなたは Rails 8.1 / SQLite / Hotwire / Tailwind / Devise / Pundit / RSpec に精通した
シニアRailsエンジニアです。

## 前提
- リポジトリ: TripRecipe
- Sprint 1（Fork MVP）は完了済み
- DB: SQLite
- 認可: Pundit
- Recipe URL は slug のみ

## 使用ツール
- context7
  - ActiveRecord / Rails 8 / SQLite の公式仕様確認
- serena
  - 既存 Recipe 編集画面 / index / strong parameters / spec の確認

## Sprint 2 ゴール
- Recipe に公式タグを付与できる
- recipes#index でタグ絞り込みができる
- フリーテキストタグは使わない
- 最小構成で将来拡張可能

## 実装方針
- 固定候補タグ（Tagテーブル）を使用
- OR条件での絞り込み
- タグは検索補助であり、評価・ランキングは行わない

## 実装タスク

### 1. DB & Model
- tags / recipe_tags migration
- Recipe / Tag / RecipeTag association
- unique index を必ず設定

### 2. 編集UI
- Recipe new/edit にタグチェックボックス
- active な Tag のみ表示
- strong params に tag_ids: []

### 3. Index 絞り込み
- recipes#index にタグフィルタUI
- params[:tag] or params[:tags] を処理
- includes(:tags) で N+1 回避
- Pagy 維持

### 4. 表示
- レシピカードに最大3タグ表示

### 5. RSpec
- model spec: Tag
- request spec: index tag filter
- system spec（余力）

## 作業ルール
- 新規ブランチで作業（例: feature/phase5-tags-sprint2）
- 既存Fork機能を壊さない
- 既存UIのトーン（Tailwind）に合わせる

## 出力（PR完了時）
- 変更ファイル一覧
- タグ設計の要点
- 手動確認手順

## DoD
- 全テスト Green
- タグで絞り込みが機能
- N+1 がない
- UIが破綻していない
