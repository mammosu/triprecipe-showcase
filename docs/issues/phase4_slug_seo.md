```markdown
## 状態: 完了

- 完了日: 2025-12-10
- 備考: 実装・主要テストが完了し、関連ドキュメントは `docs/phases/phase4_collaboration.md` に移行済み。バックアップは `docs/backup/` に保存されています。

## タイトル
Phase 4: slug / 共有リンク / SEO 強化

## 概要
公開 Recipe を共有しやすくするため、ID ベース URL から slug ベース URL へ移行し、将来の限定公開リンクや共同編集の土台を用意する。合わせて meta/OGP 設定も整備する。
## 参考
- `docs/phases/phase3_favorite.md` > Phase 4 セクション
- `docs/roadmap/ROADMAP.md`

---

## 実装メモ（slug / SEO）
## タイトル
Phase 4: slug / 共有リンク / SEO 強化

## 概要
公開 Recipe を共有しやすくするため、ID ベース URL から slug ベース URL へ移行し、将来の限定公開リンクや共同編集の土台を用意する。合わせて meta/OGP 設定も整備する。

## 目的 / KPI
- 共有 URL のクリック率改善（SNS プレビュー最適化）。
- 公開レシピの検索流入を測定できる状態をつくる。

## 実装状況 (2025-12-10)

- **ステータス**: 実装済み（主要タスクを実装、関連テストあり）
- **関連PR**: `#17` (Feature/phase4 share token)。補助の作業は `#18` にて進行中とのコメントあり。
- **実装済み（抜粋）**:
  - `recipes` に `slug` カラム追加・一意インデックス・バックフィル（migration が含まれる）。
  - `Recipe` の slug 生成ロジック、`to_param`、`fetch_by_slug!` を実装。
  - 旧 ID ベース URL → slug へのリダイレクト（コントローラで 301 を返す実装）。
  - `RecipeShareToken` モデル／`recipe_share_tokens` コントローラ（発行／無効化）と `/share/:token` 経路の実装。
  - レイアウトでの動的 meta / OGP テンプレート（`application.html.erb` と helper）を追加。
  - 基本的な Request / Model spec により slug と share token の主要挙動をカバー。

- **残タスク（優先順）**:
  - RecipeShareToken のアクセスログ（参照回数や IP、監査ログ）実装。
  - slug 再生成ポリシー（title 更新時の扱い）を決めて実装する。
  - OGP 画像（自動スクリーンショット等）の生成・連携の検討と実装。
  - PR に OGP プレビュー画像や共有URLのスクリーンショットを添付して DoD を満たす。


## タスク（案）
- [x] `recipes` に `slug` カラムを追加し、一意制約＆インデックスを設定。
- [x] slug 生成ルール（title + city + shortid 等）を docs に記載し、コールバックで自動付与。
- [x] 既存の ID ベース URL を維持しつつ、slug URL を canonical として 301/302 を設定。
- [x] 限定公開リンクの ER 図ドラフト（`share_tokens` など）と認可フロー案を docs に追記。
- [x] SEO: `<title>`, `<meta name="description">`, OGP のテンプレートを `app/views/layouts/application.html.erb` or helper に実装。
- [x] テスト: slug 生成、重複時のサフィックス、リダイレクト挙動を Request spec でカバー。
- [x] README / ROADMAP / phase3 docs に Phase4 スコープを追記。

## DoD
- slug 付き URL で公開レシピが閲覧でき、旧 URL からのアクセスも問題なく遷移する。
- 限定公開リンクの仕様メモ（作成/無効化/API ポイント）が docs にまとまっている。
- CI（`bundle exec rspec` + `bundle exec rubocop -f github`）を通過。
- PR に共有URLのスクリーンショット、OGP プレビュー例を添付。

## 参考
- `docs/phases/phase3_favorite.md` > Phase 4 セクション
- `docs/roadmap/ROADMAP.md`

---

## 実装メモ（slug / SEO）

### slug 生成ルール
- 形式: `parameterize(title + "-" + city)` をベースとし、重複時は `-2`, `-3` ... のような連番を付与。
- title/city から ASCII 文字が生成できない場合（例: 日本語のみ）は `tpxxxxxx` 形式（`tp` + 英数字6桁）をフォールバックとして生成する。
- Title / City を更新した際は再度上記ルールで slug を再生成し、旧 slug は `recipe_slugs` テーブルに履歴として保存した上で 301 リダイレクトを返す。
- 旧 slug でアクセスされた場合は `RecipeSlug` を参照して対象レシピを解決し、詳細画面で canonical slug へ恒久リダイレクトする。
- `Recipe#to_param` は slug を返すため、`recipe_path(@recipe)` で常に slug URL を出力。
- 旧 ID ベース URL は `fetch_by_slug!` で解決を試みますが、数値 ID のみのアクセスは 404 を返すようになりました（スラッグ専用ポリシー）。

### SEO / OGP
- `app/views/layouts/application.html.erb` に共通 `<meta name="description">` と OGP (`og:title`, `og:description`, `og:url`, `og:site_name`, `og:type`) を追加。
- Recipe 詳細では `content_for :title`, `:meta_description`, `:canonical_url` をセットし、SNS でプレビューしやすいように 150 文字に truncate。
- デフォルト meta description は `TripRecipe` のサービス説明文を `ApplicationHelper::DEFAULT_META_DESCRIPTION` で提供。

### RecipeShareToken 実装概要

```mermaid
erDiagram
  recipes ||--o{ share_tokens : has

  recipes {
    integer id PK
    integer user_id FK
    string slug
  }

  share_tokens {
    integer id PK
    integer recipe_id FK
    string token UNIQUE
    datetime expires_at
    datetime revoked_at
    datetime created_at
  }
```

- token: URL セーフな 24 文字。`/share/:token` にアクセスすると slug URL へリダイレクトし、`share_token` パラメータで限定表示。
- 認可: `RecipeShareToken.active` で `revoked_at` / `expires_at` を判定し、`RecipesController#authorize_visibility!` が共有アクセスを許容。
- 無効化: レシピ詳細画面から「再発行」「無効化」ボタンで `Recipes::ShareTokensController` を呼び出し、既存 token を revoke。
- 運用: `RecipeShareAccessLog` でアクセス履歴 (`accessed_at`, IP, UA) を自動記録し、詳細画面に直近アクセス・履歴テーブルを表示。期限延長ボタン(30日)で TTL を更新し、再発行履歴もテーブルで確認可能。
- Audit: 今後 `recipe_share_access_logs` で参照回数や IP を記録する余地あり。

### 課題 / 次アクション
1. RecipeShareToken のアクセスログ（誰がいつ閲覧したか）や期限延長 UI を検討。
2. slug 再生成ポリシー（title 更新時の再生成可否）と 301/410 の扱いを決定。
3. meta image（OGP画像）生成、自動 screenshot 連携を検討。
