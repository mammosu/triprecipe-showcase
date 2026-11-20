# Phase 5 – Sprint 2 PRタスクリスト（Tag導入 MVP）

本Sprintでは **レシピの発見性向上** を目的に、
「固定候補タグ」を用いた **安全・軽量なタグ機能** を導入する。

---

## Sprint 2 ゴール
- Recipe に公式タグを付与できる
- recipes#index でタグ絞り込みができる
- UI / DB / テストが最小構成で成立している
- 将来拡張（検索重み・ランキング）を阻害しない

---

## PR1: タグ用DB設計（tags / recipe_tags）

### 目的
フリーテキストを避け、**運用可能な公式タグ**を実現する。

### 変更内容
- migration
  - `tags`
    - key:string (unique, null:false)
    - label_ja:string
    - position:integer
    - active:boolean (default:true)
  - `recipe_tags`
    - recipe_id
    - tag_id
    - unique index (recipe_id, tag_id)
- model
  - Recipe
    - has_many :recipe_tags, dependent: :destroy
    - has_many :tags, through: :recipe_tags
  - Tag
    - has_many :recipe_tags
    - has_many :recipes, through: :recipe_tags

### DoD
- schema.rb 更新
- console で Recipe.first.tags が取得できる

---

## PR2: タグ編集UI（Recipe編集画面）

### 目的
作者が **安全にタグを付与/変更** できるようにする。

### 変更内容
- Recipe edit / new
  - activeなTagをチェックボックスで表示
  - strong parameters に tag_ids: [] を追加
- Controller
  - tags 更新時に transaction を使用
- 表示制限
  - owner / editor / admin のみ編集可（既存Pundit流用）

### DoD
- タグの追加・削除が保存できる
- 不正な tag_id は無視 or エラー

---

## PR3: recipes#index タグ絞り込み

### 目的
一覧ページで **探せる状態** を作る。

### 変更内容
- UI
  - タグフィルタ（chips or checkbox）
- Controller
  - params[:tag] or params[:tags]
  - MVPでは OR 条件で絞り込み
- Query
  - includes(:tags) で N+1 回避
- 表示
  - カードに最大3タグ表示

### DoD
- ?tag=family 等で絞り込み可能
- Pagy が維持されている
- N+1 が発生しない

---

## PR4: RSpec（タグMVP）

### 目的
タグ機能の基本挙動を壊さない。

### テスト内容
- model spec
  - Tag validation
  - Recipe-tag association
- request spec
  - recipes#index with tag filter
- system spec（任意）
  - フィルタ操作で結果が変わる

### DoD
- 全テスト Green
- タグ周りの仕様がテストで説明されている

---
