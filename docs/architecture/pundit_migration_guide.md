# Pundit Authorization Migration Guide

## 概要
Phase 4 で Pundit を導入し、認可（Authorization）の仕組みを刷新しました。
今後、コントローラーやビューでの権限チェックは Pundit の Policy を使用して行います。

## 基本的な使い方

### コントローラー

`include Pundit::Authorization` が `ApplicationController` に追加されています。

```ruby
# Before (独自のメソッドなど)
before_action :authorize_owner!, only: [:edit, :update]

# After (Pundit)
def update
  @recipe = Recipe.fetch_by_slug!(params[:id])
  authorize @recipe # RecipePolicy#update? が呼ばれる
  
  if @recipe.update(recipe_params)
    # ...
  end
end
```

### ビュー

ビュー内でも `policy` ヘルパーが使用可能です。

```erb
<%# Before %>
<% if current_user == @recipe.user %>
  <%= link_to "編集", edit_recipe_path(@recipe) %>
<% end %>

<%# After %>
<% if policy(@recipe).update? %>
  <%= link_to "編集", edit_recipe_path(@recipe) %>
<% end %>
```

## RecipePolicy の権限ルール

| アクション | メソッド | 条件 |
|-----------|---------|------|
| 閲覧 | `show?` | 公開レシピ OR オーナー OR コラボレーター OR 共有トークン |
| 作成 | `create?` | ログインユーザー |
| 更新 | `update?` | オーナー OR editor/admin権限のコラボレーター |
| 削除 | `destroy?` | オーナーのみ |
| コラボレーター管理 | `manage_collaborators?` | オーナー OR admin権限のコラボレーター |

## 新しいロール定義

`RecipeCollaborator` モデルで定義されています。

- **viewer**: 閲覧のみ
- **editor**: 閲覧 + 編集
- **admin**: 閲覧 + 編集 + コラボレーター管理

## 今後の作業のための注意点

1. **既存コントローラーの移行（完了）**:
   - `RecipesController`, `RecipeDaysController`, `RecipeStepsController`, `ShareTokensController` は Pundit の `authorize` メソッドへの移行が完了しました。
   - レガシーな `authorize_owner!` メソッドは削除されました。

2. **テスト**:
   - 権限回りのテストは `spec/policies` に記述することを推奨します。
   - System Spec では、ユーザーのロールに応じた振る舞い（ボタンの表示/非表示など）を確認してください。
