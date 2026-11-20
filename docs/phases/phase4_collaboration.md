# Phase 4: 共有とコラボレーション

Phase 4 では、レシピの共有範囲を広げるための限定公開リンクと、複数ユーザーでレシピを編集するためのコラボレーション機能を実装しました。また、認可システムを Pundit へ移行し、堅牢な権限管理を実現しています。

## 🎯 目的 / ユースケース
- **限定公開**: アカウントを持たない友人にも、一時的なリンクでレシピを共有したい（閲覧専用）。
- **共同編集**: 旅行に行くメンバー（パートナーや家族）と一緒にレシピを編集したい。
- **SEO/OGP**: SNS でシェアされた際に、リッチなプレビュー（タイトル、説明、画像）を表示したい。

## ✅ DoD Checklist (Completed)
- [x] **Slug URL & Redirects**:
  - タイトル変更時の自動 Slug 更新と旧 Slug からの 301 リダイレクト。
  - `/recipes/123` 形式の無効化（404化）。
- [x] **RecipeShareToken (限定公開リンク)**:
  - トークン発行、無効化、再発行、有効期限（30日）延長。
  - アクセスログ (`RecipeShareAccessLog`) の記録と表示。
- [x] **SEO & OGP**:
  - `seo_page_title`, `seo_meta_description` ヘルパーの実装。
  - 各ページでの適切な meta タグ出力。
- [x] **Collaboration (共同編集)**:
  - `RecipeCollaborator` モデルと 3 段階のロール (admin, editor, viewer)。
  - 招待（メール）、承認、辞退、ロール変更、削除のフロー。
  - コラボレーター管理 UI の実装。
- [x] **Pundit Authorization**:
  - `RecipePolicy` への認可ロジック集約。
  - コントローラ (`RecipesController`, `RecipeDaysController` etc.) の Pundit 移行。

## 🧱 データモデル (Collaboration)
```mermaid
erDiagram
  users ||--o{ recipe_collaborators : has
  recipes ||--o{ recipe_collaborators : has

  recipe_collaborators {
    integer id PK
    integer user_id FK
    integer recipe_id FK
    integer role "0:viewer, 1:editor, 2:admin"
    integer status "0:pending, 1:accepted, 2:rejected"
    timestamps
  }
```

## 🔐 権限テーブル (RecipePolicy)

| Action | Owner | Collab: Admin | Collab: Editor | Collab: Viewer | Public | Private (Token) |
|---|---|---|---|---|---|---|
| Show | ✅ | ✅ | ✅ | ✅ | ✅ (if public) | ✅ (if valid token) |
| Update (Recipe) | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Destroy (Recipe) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Manage Collaborators | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Create Day/Step | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |

## 🔜 Future Work (Phase 5+)
- メール通知の非同期配信（招待メールの実装）。
- 監査ログの強化（誰がいつ変更したか）。
- コメント機能（コラボレーター間のやりとり）。
