# Phase 3: SavedRecipe & 発見導線

TripRecipe に公開レシピのブックマーク導線を追加し、他ユーザーのプランを再訪しやすくするフェーズ。ProductPlannerAgent / RailsArchitectAgent / RailsCoderAgent / TestEngineerAgent が共通認識をもてるよう仕様を整理する。

## 🎯 目的
- 公開 Recipe を「お気に入り」として保存し、後から一覧表示できる。
- タップ 1 回で登録/解除できる CTA を Recipe 詳細に配置し、モバイルでも扱いやすくする。
- マイページ（現状は Recipes#index 内のマイセクション）にお気に入り一覧を表示し、発見導線を作る。

## ✅ DoD
- [x] `favorites` テーブル（`user_id`, `recipe_id`）を追加。複合 UNIQUE と `foreign_key` 制約で整合性を確保。
- [x] `SavedRecipe` モデル、`User has_many :favorites` / `Recipe has_many :favorited_users, through: :favorites` を定義。
- [x] `SavedRecipesController#index` で自分のお気に入りプラン一覧を表示。ログイン必須。
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
- 未ログイン or 自分のプランには表示文言で誘導。

## タスク分解
1. **Schema**: migration + model + spec（unique index、presence）
2. **Association**: User/Recipe に関連＆ helper メソッド `favorited_by?(user)` を追加
3. **Controllers**: `SavedRecipesController#index` + `Recipes::SavedRecipesController` create/destroy actions
4. **Views**: Recipe show の CTA、Recipes index に favorites セクション、`favorites/index.html.erb`
5. **Tests**: model + request spec
6. **Docs**: README MVP 更新、ROADMAP state 更新、Issue 作成

## リスク/メモ
- 非公開プランはお気に入り対象外。サーバーサイドで `recipe.public?` を enforce。
- 自分のプランをお気に入り登録する仕様は今回は許可（共有導線として faves 0 になるのを避ける）。将来 flag で制御。
- パフォーマンス: `Recipe` 取得時に favorites カウントを eager load する必要があれば counter cache を検討（Phase3 scope外）。

## 次アクション
1. Phase 4（共有リンク/SEO）: slug 設計や公開リンクの認可モデルを検討し、PoC Issue を起票する。
2. 人気プラン集計のキャッシュ方針や期間切り替え UI（7日/30日/全期間）を検証し、パフォーマンス改善を図る。
3. SavedRecipes API や通知（新着お気に入り）など拡張施策を backlog に積む。
4. RecipeShareToken（限定公開リンク）でプライベートプランを一時共有できるようにし、閲覧ログや期限管理を整備する。

---

## Phase 3.5: 発見導線の強化

### ゴール
- ホーム/一覧で「人気プラン」「最近のお気に入り」を表示し、他ユーザーのプラン発見を促す。
- プランカードにお気に入り数バッジを表示し、人気度を可視化する。
- 再訪用のリマインダー導線（例: メール通知やトップカード）を最小構成で検証する。

### 実装内容（✅ 完了）

#### 1. モデル層の強化
- **`Recipe.with_favorites_count`**: すべてのプランにお気に入り数を付与する scope
  - LEFT JOIN で `favorites` を集計し、`favorites_count` 属性を追加
  - N+1 問題を回避するために使用
- **`Recipe.popular_recipes(limit: 5)`**: 人気プランを取得する scope
  - 直近30日間のお気に入り数でソート
  - 公開プラン（`public: true`）のみを対象
  - お気に入り数の降順、更新日時の降順でソート
  - デフォルトで上位5件を取得

#### 2. コントローラーの更新
- **`RecipesController#index`**:
  - `@popular_recipes` 変数を追加（人気プラン top 5）
  - `@public_recipes` クエリに `with_favorites_count` を適用してお気に入り数を取得

#### 3. ビュー（UI）の改善
- **「人気のプラン」セクション**:
  - 🔥 アイコンとピンク/ローズ系の配色で視覚的に目立たせる
  - 直近30日間のお気に入り数が多い上位5件を表示
  - お気に入り数バッジ（★ N）を各カードに表示
  - プラン詳細へのリンク、都市、日数、作成者情報を表示
- **公開プランギャラリー**:
  - 各カードにお気に入り数バッジを表示（0件の場合は非表示）
  - アンバー系の配色でお気に入り数を強調
- **お気に入りセクションの空状態改善**:
  - お気に入りが0件の場合、「人気のプラン」セクションへの誘導メッセージを追加

#### 4. テストカバレッジ
- **モデル Spec (`spec/models/recipe_spec.rb`)**:
  - `with_favorites_count` scope のテスト
  - `popular_recipes` scope のテスト（公開/非公開の分離、ソート順、件数制限、30日制限）
- **リクエスト Spec (`spec/requests/recipes_spec.rb`)**:
  - 人気プランセクションの表示確認
  - 非公開プランが人気プランに含まれないことを検証
  - お気に入り数順のソート検証
  - お気に入り数バッジの表示確認
- **テスト結果**: 56 examples, 0 failures
- **Linter**: RuboCop Rails Omakase - 違反なし

### セキュリティとパフォーマンス
- ✅ 非公開プランは人気プランセクションから完全に除外
- ✅ SQL インジェクション対策：ActiveRecord の scope を使用
- ✅ N+1 問題対策：`with_favorites_count` による一括集計
- ⚠️ 将来的な最適化案：
  - 1000件以上のプランがある場合、counter cache の導入を検討
  - Redis によるキャッシュ（1時間程度）で集計クエリの負荷軽減

### UI/UX 変更点
- **発見性向上**: ユーザーは人気プランを簡単に見つけられるようになった
- **社会的証明**: お気に入り数バッジにより、人気度が可視化され、クリック率（CTR）向上が期待できる
- **空状態の改善**: お気に入りが0件のユーザーに対して、人気プランへの誘導を強化

### 今後の拡張案
1. **検索/フィルタリング**: 都市、日数、カテゴリによるフィルター機能
2. **パーソナライズ**: ユーザーの過去の閲覧履歴やお気に入りに基づくレコメンデーション
3. **期間指定**: 直近7日、30日、全期間など、期間を切り替えられる UI
4. **ランキングページ**: 独立したページで人気プランのランキングを表示

---

## Phase 4: 共有/SEO（実装サマリ）

### ゴール
- 公開プランを slug ベース URL で配信し、ID URL からは 301 で canonical へ誘導。
- RecipeShareToken による限定公開リンクを MVP として提供し、アクセスログや期限延長を含む運用機能を整備。
- SEO テンプレートと OGP メタをヘルパーで統一し、共有時のプレビュー品質を高める。

### 実装済みタスク
| 担当 | 内容 |
| --- | --- |
| ProductPlanner | 共有 CTA / slug 命名規則を定義。共有リンクのオンボーディング文言を README/ROADMAP に反映。|
| RailsArchitect | `recipes.slug` + unique index、`recipe_slugs` 履歴テーブル、`share_tokens` + `recipe_share_access_logs` ERD を確定。|
| RailsCoder | slug 自動生成＆旧 slug 恒久リダイレクト、RecipeShareToken CRUD + TTL 延長 UI、アクセスログ記録、SEO ヘルパー・OGP テンプレを実装。|
| TestEngineer | slug 世代・リダイレクト・RecipeShareToken 権限・アクセスログ作成・TTL 延長の Model/Request spec を追加。|
| DevOps | 今後の計測を見据え、アクセスログを DB 保存する仕組みを整備（将来は可視化/通知へ拡張余地）。|

### DoD
- slug URL を canonical として提供し、旧 ID URL／旧 slug から 301 で遷移する。
- RecipeShareToken で限定公開リンクを発行し、アクセスログ/履歴/期限延長 UI を Recipe 詳細画面で閲覧可能。
- `ApplicationHelper` の SEO ヘルパー経由で `<title>` / `<meta name="description">` / OGP タグを全ページに統一適用し、README/ROADMAP/本ドキュメントに Phase4 スコープを明記。
