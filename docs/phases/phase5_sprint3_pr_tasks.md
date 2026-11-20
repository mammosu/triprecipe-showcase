# Phase 5 – Sprint 3 PRタスクリスト（Trust & Safety / 通報 + Avo）

本Sprintでは Fork/Tag によって増える公開コンテンツを
**最小運用コストで安全に管理できる状態**を作る。

---

## Sprint 3 ゴール
- 公開レシピを通報できる
- 管理側（Avo）で確認・対応できる
- 不適切コンテンツを即座に非公開化できる
- プロダクトの信頼性を損なわない

---

## PR1: 通報用DB設計（recipe_reports）

### 目的
ユーザーからの通報を永続化し、運用可能にする。

### 変更内容
- migration
  - recipe_reports
    - recipe_id (null:false)
    - user_id (null:false)
    - reason (enum)
    - comment
    - status (default: open)
    - handled_by_user_id
  - unique index (recipe_id, user_id)
- model
  - RecipeReport
    - enum :reason
    - enum :status
  - Recipe
    - has_many :recipe_reports

### DoD
- schema.rb 更新
- console で通報作成が可能

---

## PR2: Pundit & Controller（通報）

### 目的
公開レシピのみ、安全に通報できるようにする。

### 変更内容
- Policy
  - RecipeReportPolicy#create?
    - user.present?
    - recipe.public?
- Controller
  - Recipes::ReportsController#create
  - 重複通報は update 扱い（find_or_initialize_by）
- routes
```ruby
resources :recipes do
  resource :report, only: :create, controller: "recipes/reports"
end
```

### DoD
- 未ログイン不可
- 非公開レシピ不可
- 同一ユーザーは1通報のみ

---

## PR3: UI（通報導線）

### 目的
ユーザーが迷わず通報できるようにする。

### 変更内容
- recipes/show
  - 「通報」リンク追加（公開レシピのみ）
- Turbo modal
  - reason 選択
  - comment 任意入力
- 送信後
  - flash / toast 表示

### DoD
- UI から通報可能
- 二重送信しても重複しない

---

## PR4: Avo Resource（運用）

### 目的
管理者が通報を確認・対応できるようにする。

### 変更内容
- Avo::Resources::RecipeReport
  - 一覧表示
  - ステータス更新
- 管理アクション
  - 対象レシピを非公開化

### DoD
- Avo から通報を確認できる
- 管理操作でレシピを非公開にできる

---

## PR5: RSpec（Trust & Safety）

### 目的
通報機能の破壊を防ぐ。

### テスト内容
- model spec
- request spec
- policy spec

### DoD
- 全テスト Green
- 通報仕様がテストで説明されている
