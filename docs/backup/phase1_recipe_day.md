# Phase 1: RecipeDay 基盤

ロードマップの Phase 1 を具体的に進めるための仕様メモ。ProductPlannerAgent と RailsArchitectAgent が同期し、RailsCoderAgent/TestEngineerAgent へ実装指示を渡すことを想定します。

## 🎯 目標 / 成功指標
- ユーザーが既存の Recipe を日次単位に分解できる。
- 1 日あたりの概要（タイトル/メモ/日付）が登録でき、順序を並び替えられる。
- 認可は Recipe owner に準拠（公開レシピ閲覧時は日次詳細も表示のみ）。
- Request / Model spec を整備し、`bin/ci` に組み込まれた RSpec が成功する。

## ✅ DoD チェック
- [x] Recipe との 1:N 関連をマイグレーションとモデルで定義 (`has_many :recipe_days, -> { order(:day_order) }, dependent: :destroy`).
- [x] `recipe_days` テーブルを追加し、下記制約を DB レベルでも保証。
  - `recipe_id` (FK, NOT NULL, cascade delete)
  - `day_order` (INTEGER, NOT NULL, default 自動採番, unique per recipe)
  - `title` (string, NOT NULL, <= 100 char)
  - `notes` (text, NULL 可, <= 2000 char)
  - `starts_on` (date, NULL 可)
  - timestamps
- [x] Recipe 詳細ページで RecipeDay リストを表示（公開レシピは閲覧のみ、owner は CRUD）。
- [x] Nested routes: `resources :recipes do resources :recipe_days end`（`only: %i[new create edit update destroy]` + show? optional).
- [x] Strong parameters + owner 認可を Concern または Pundit に抽出し、Recipe/RecipeDay 双方で再利用。
- [x] RSpec: Model spec (validation, ordering callback), Request spec (create/update/destroy, authorization)。System spec 任意。
- [x] README/ROADMAP 更新済み（リンク済み）。

## 📐 データモデル案
```mermaid
erDiagram
  users ||--o{ recipes : has
  recipes ||--o{ recipe_days : has

  recipes {
    integer id PK
    integer user_id FK
    string title
    boolean public
    timestamps
  }

  recipe_days {
    integer id PK
    integer recipe_id FK
    integer day_order
    string title
    text notes
    date starts_on
    timestamps
  }
```

### バリデーション
- `title`: presence, length ≤ 100
- `day_order`: presence, numericality (≥1), uniqueness scoped to `recipe_id`
- `notes`: optional, length ≤ 2000
- `starts_on`: optional, >= `recipe.starts_on` (将来 Recipe に基準日があれば)

### コールバック
- `before_validation` で `day_order` 未指定時は `recipe.recipe_days.maximum(:day_order).to_i + 1` を採番。

## 🛣️ ルーティング & コントローラ
```rb
resources :recipes do
  resources :recipe_days, except: :index
end
```

- Index 相当は Recipe show 内で扱う。
- Controller は `RecipeScoped` concern を作り、`set_recipe`/`authorize_owner!` を再利用。
- 強制的に owner のみアクセス可能（view-only path は Recipe#show で `@recipe.recipe_days` を preload）。

## 🧑‍🎨 UX/コピー
- Recipe show に「日程を追加」CTA を配置。モバイルでは FAB。
- RecipeDay フォーム項目:
  - タイトル（例: 1日目 バルセロナ旧市街）
  - 日付（任意）
  - メモ（テキストエリア）
- 並び替え: Phase 1 では単純な `day_order` up/down ボタンで対応。ドラッグは Phase 2+。

## 📋 タスク分解
1. **Schema**: migration + model + spec (`RecipeDay`).
2. **Association**: `Recipe` に `has_many :recipe_days` + `accepts_nested_attributes_for` (必要なら) を追加。
3. **Controller/View**: `RecipeDaysController` (new/create/edit/update/destroy) + partials。
4. **Authorization Refactor**: `owns_recipe?` の共通化（ApplicationController helper → Concern or Service）。
5. **Specs**: Model + Request + （任意）System (owner vs guest)。
6. **Docs**: README 「機能概要」に RecipeDay 追記、ROADMAP check 更新。

## 📌 依存/リスク
- Recipe の `days_count` と整合性: RecipeDay 作成/削除時に自動更新するか検討。Phase 1 ではバックログ（警告のみ）。
- 並び替え UI: Phase 1 では最小限、将来 Stimulus sortable を導入。
- 認可: 今後 Pundit 導入を想定し、Concern 抽出で移行コストを下げる。

## 🔜 次ステップ
1. この仕様に沿った Issue (`feat: recipe day CRUD`) を作成。
2. RailsArchitectAgent がマイグレーション/モデル詳細をレビュー。
3. `feature/recipe-day-phase1` ブランチで実装を進め、PR に本メモをリンク。
