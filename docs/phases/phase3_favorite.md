# Phase 3: SavedRecipe & 発見導線

TripRecipe に公開レシピのブックマーク導線を追加し、他ユーザーのレシピを再訪しやすくするフェーズ。ProductPlannerAgent / RailsArchitectAgent / RailsCoderAgent / TestEngineerAgent が共通認識をもてるよう仕様を整理する。

## 🎯 目的
- 公開 Recipe を「お気に入り」として保存し、後から一覧表示できる。
- タップ 1 回で登録/解除できる CTA を Recipe 詳細に配置し、モバイルでも扱いやすくする。
- マイページ（現状は Recipes#index 内のマイセクション）にお気に入り一覧を表示し、発見導線を作る。

## ✅ DoD
- [x] `favorites` テーブル（`user_id`, `recipe_id`）を追加。複合 UNIQUE と `foreign_key` 制約で整合性を確保。
- [x] `SavedRecipe` モデル、`User has_many :favorites` / `Recipe has_many :favorited_users, through: :favorites` を定義。
- [x] `SavedRecipesController#index` で自分のお気に入りレシピ一覧を表示。ログイン必須。
- [x] `Recipes` へのネストルート（`resource :favorite, only: %i[create destroy]`）で登録/解除を実装。
- [x] UI: Recipe 詳細にトグルボタン、一覧ページに「お気に入り」カード群を追加。
- [x] RSpec: SavedRecipe model（バリデーション）、Request spec（create/destroy/index 認可）。
- [x] README/ROADMAP/Issue 更新、Swagger 等なし。

## モデル & ルーティング
```mermaid
erDiagram
  users ||--o{ favorites : has
  recipes ||--o{ favorites : receives

  favorites {
    integer id PK
    integer user_id FK
    integer recipe_id FK
    timestamps
  }
```

```rb
resources :favorites, only: :index
resources :recipes do
  resource :favorite, only: %i[create destroy]
end
```

## UX
- 詳細ボタン: オーナー以外のサインインユーザーに「☆ お気に入り登録 / ★ 解除」。クリックで Turbo 対応（Phase3++）。MVP は通常リダイレクト。
- お気に入り一覧: カードを最大 6 件表示し、作成者・都市・日数等のスナップショットを表示。
- 未ログイン or 自分のレシピには表示文言で誘導。

## タスク分解
1. **Schema**: migration + model + spec（unique index、presence）
2. **Association**: User/Recipe に関連＆ helper メソッド `favorited_by?(user)` を追加
3. **Controllers**: `SavedRecipesController#index` + `Recipes::SavedRecipesController` create/destroy actions
4. **Views**: Recipe show の CTA、Recipes index に favorites セクション、`favorites/index.html.erb`
5. **Tests**: model + request spec
6. **Docs**: README MVP 更新、ROADMAP state 更新、Issue 作成

## リスク/メモ
- 非公開レシピはお気に入り対象外。サーバーサイドで `recipe.public?` を enforce。
- 自分のレシピをお気に入り登録する仕様は今回は許可（共有導線として faves 0 になるのを避ける）。将来 flag で制御。
- パフォーマンス: `Recipe` 取得時に favorites カウントを eager load する必要があれば counter cache を検討（Phase3 scope外）。

## 次アクション
1. Phase 4（共有リンク/SEO）: slug 設計や公開リンクの認可モデルを検討し、PoC Issue を起票する。
2. 人気レシピ集計のキャッシュ方針や期間切り替え UI（7日/30日/全期間）を検証し、パフォーマンス改善を図る。
3. SavedRecipes API や通知（新着お気に入り）など拡張施策を backlog に積む。

---

## Phase 3.5: 発見導線の強化

### ゴール
- ホーム/一覧で「人気レシピ」「最近のお気に入り」を表示し、他ユーザーのレシピ発見を促す。
- レシピカードにお気に入り数バッジを表示し、人気度を可視化する。
- 再訪用のリマインダー導線（例: メール通知やトップカード）を最小構成で検証する。

（以下略：元の文書の詳細を保持）
