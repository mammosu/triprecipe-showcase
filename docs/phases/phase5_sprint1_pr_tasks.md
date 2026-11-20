# Phase 5 – Sprint 1 PRタスクリスト（Fork MVP）

本ファイルは TripRecipe Phase 5 の **Sprint 1（Fork MVP）** を
GitHub PR 単位で実装するためのタスクリストです。
そのまま issue / PR 説明文として利用できます。

---

## Sprint 1 ゴール
- 公開レシピを **Fork（コピー）** して自分のレシピとして編集できる
- Day / Step の構造と順序が保持される
- slug URL のみで遷移できる
- セキュリティ（Pundit）と最低限のテストが担保される

---

## PR1: DB & モデル土台（fork元参照 + slug補助）

### 目的
Fork の出自を安全に保持し、後続実装の基盤を作る。

### 変更内容
- migration
  - `recipes.forked_from_recipe_id :integer, null: true`
  - index 追加
- model
  - `Recipe`
    - `belongs_to :forked_from_recipe, class_name: "Recipe", optional: true`
    - `has_many :forks, class_name: "Recipe", foreign_key: :forked_from_recipe_id`
- （必要に応じて）
  - slug 衝突回避用のヘルパー / service 追加

### DoD
- schema.rb が更新されている
- 既存テストがすべて通る
- forked_from_recipe を参照できる

---

## PR2: Pundit & Routes（Fork権限の明確化）

### 目的
Fork を **公開レシピ限定・ログイン必須** に制限する。

### 変更内容
- `RecipePolicy`
  - `fork?` を追加
    - `user.present?`
    - `record.public?`
- routes
```ruby
resources :recipes do
  post :fork, on: :member
end
```

### DoD
- 未ログインでは fork 不可
- 非公開レシピでは fork 不可
- Pundit 経由で必ずチェックされている

---

## PR3: Forkサービス + Controller（中核）

### 目的
Fork処理を安全にトランザクションで実装する。

### 変更内容
- `app/services/recipe_fork_service.rb`
  - `Recipe.transaction` を使用
  - Recipe 複製
    - user: current_user
    - visibility: private
    - forked_from_recipe_id セット
  - RecipeDay 複製（順序保持）
  - RecipeStep 複製（順序保持）
  - slug をユニーク生成
  - 監査ログ/バージョンは fork 1件のみ残す（Day/Stepは抑制）
- controller
  - `RecipesController#fork`
  - `authorize @recipe, :fork?`
  - 成功時: 新レシピへリダイレクト
  - 失敗時: flash + 元ページ

### DoD
- Fork後に Day / Step 件数が一致
- 並び順が保持されている
- 500エラーにならない

---

## PR4: UI導線（CTA + attribution）

### 目的
ユーザーが迷わず Fork を使えるようにする。

### 変更内容
- `recipes/show`
  - 「このレシピをベースに作る」ボタン
  - 表示条件: `policy(@recipe).fork?`
- attribution 表示
  - コピー先レシピに元レシピ情報を表示
  - 元が公開ならリンク、非公開ならテキストのみ

### DoD
- 公開レシピにのみ CTA が表示される
- Fork後、コピー先で attribution が確認できる

---

## PR5: RSpec（Fork MVP）

### 目的
壊れやすい複製ロジックを自動テストで固定する。

### テスト内容
- service spec
  - Day / Step 件数一致
  - position 順序一致
  - forked_from_recipe_id セット
  - slug 重複回避
- request spec
  - 未ログイン不可
  - 非公開不可
- system spec
  - 公開詳細 → Fork → 新レシピ遷移

### DoD
- 全テスト Green
- Fork 周辺の仕様がテストで説明されている

---
