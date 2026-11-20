# TripRecipe ロードマップ

最終更新: 2025-12-19 (Phase 4 実装完了 + 監査ログ強化/日本語化まで反映)

**コンテキスト**
- 現状: Phase 4 完了に加え、監査ログの基盤（last_edited_by + audit_logs + 通知/保持ジョブ + 日本語化/UI改善）を導入済み。限定公開リンクや人気レシピの品質も本番水準。PaperTrail による履歴記録と履歴 UI（Recipe/RecipeDay/RecipeStep）は導入済みで、Recipe の基本復元も対応。次は差分表示の磨き込みと RecipeDay/RecipeStep の復元対応、リリース準備ドキュメントの整備。
- 方針: AGENTS.md に従い、MVP志向で段階的に機能を拡張します（Recipe → RecipeDay → RecipeStep → SavedRecipe → Audit/差分）。各フェーズで ProductPlannerAgent と RailsArchitectAgent を連携させます。

**フェーズ別ロードマップ（概要）**

- **Phase 0: Recipe MVP** — 完了
	- ProductPlanner DoD: 公開/非公開切替付きの Recipe CRUD、Devise による認証
	- RailsArchitect: `recipes` テーブル、`owns_recipe?` によるオーナー判定

- **Phase 1: RecipeDay 基盤** — 完了
	- ProductPlanner DoD: Recipe を日単位で分割できる。RecipeDay の作成/編集/削除 UI。日付とメモを必須にする。RSpec（Request + Model）あり。
	- RailsArchitect: `recipe_days` テーブル（`recipe_id`,`day_order`,`title`,`notes`,`starts_on`）、`Recipe has_many :recipe_days`、ネストルート `/recipes/:id/days`、オーナー判定を再利用可能な concern/サービスへ抽出。

- **Phase 2: RecipeStep（行動詳細）** — 完了
    - ProductPlanner DoD: 各 RecipeDay にアクティビティを登録し時間順に表示。入力フォーム・並び替えボタン・開始<=終了バリデーションを提供済み。
    - RailsArchitect: `recipe_steps` テーブルと `has_many` 関連、`RecipeStepsController`、ネストルート、position 自動採番・移動ロジックを実装済み。

- **Phase 3: SavedRecipe & 発見導線** — 完了
    - ProductPlanner DoD: 公開レシピのお気に入り登録/解除、マイページでのお気に入り一覧、重複登録防止、リクエストスペックでの回帰を網羅。
    - RailsArchitect: `favorites` ジョインテーブル（`user_id`,`recipe_id` + unique index）を追加し、`Recipe.visible_to` スコープで非公開レシピを自動除外。所有者チェックを `RecipeScoped` concern へ集約。

- **Phase 3.5: SavedRecipes 発見導線の強化** — 完了
    - ProductPlanner DoD: Recipes#index に「人気のレシピ」セクションとお気に入り数バッジを表示し、空状態からの導線コピーを改善。
    - RailsArchitect: `Recipe.with_favorites_count` / `popular_recipes` scope を追加し、直近30日の公開レシピのみを集計。Request spec と seed データで回帰を担保。

- **Phase 4: 共有とコラボ** — 完了（リリース準備中）
	- slug ベース URL / canonical リダイレクトと OGP meta に加え、タイトル・都市変更時の自動 slug 再生成と旧 slug の恒久リダイレクトを実装済み。
	- RecipeShareToken による限定公開リンク: 発行/無効化/再発行、30日延長ボタン、`RecipeShareAccessLog` でアクセス履歴（IP/UA/時刻）を自動記録し、Recipe 詳細で履歴テーブルを表示。
	- SEO テンプレート: `ApplicationHelper` に `seo_page_title` / `seo_meta_description` / OGP 出力ヘルパーを追加し、サイト全体で統一した meta タグを適用。
	- 共同編集機能（Collaboration）:
		- Pundit 導入: `Policy` クラスによる明示的な権限管理への移行基盤を確立。
		- RecipeCollaborator: 3段階のロール（viewer/editor/admin）による共同編集者管理。
		- 管理 UI: 招待（メールアドレスベース）、承認/辞退フロー、ロール変更、削除機能を実装。
		- `RecipePolicy`: 公開設定、所有権、コラボレーション、共有リンクを統合した権限ルールを実装。
		- **リファクタリング（Phase 5）**: 既存コントローラー（Recipe, Day, Step）の認可ロジックを Pundit へ完全移行完了。
	- 監査ログ（拡張）: last_edited_by（ID+メール併存）、audit_logs の非同期記録、日次サマリ通知、保持ポリシー（90日）、item_id 非表示＋日本語ラベル化、actor_email 表示、履歴UI部分テンプレート化。
	- PaperTrail 履歴: versions テーブル、Recipe/RecipeDay/RecipeStep の変更履歴 UI（一覧/詳細）を追加。Recipe の復元は基本対応。
	- 次ステップ: 差分 UI の磨き込み/復元対象の拡張、招待通知メールの強化。

**バックログ（優先度）**

- MUST
	- RecipeDay CRUD UI とモデルバリデーション（Phase 1完了）
	- Nested routing と認可のリファクタ（`owns_recipe?` を concern/service に抽出）
	- RecipeStep スキーマと並び替え API（Phase 2完了、ドラッグ操作は後続バックログ）

- SHOULD
	- 人気レシピ集計のキャッシュ/期間切替や個別おすすめなど Phase 3.5 の発展タスク
	- 限定公開リンク (RecipeShareToken) のさらなるUX拡張（複数リンク/ロール付与、ログの可視化、通知）

- COULD
	- 共有リンクのアクセス分析（別テーブル or 外部サービス）

**DoD（各フェーズ共通）**

1. **ProductPlanner**: ユーザーストーリーと完了条件を README または Issue に反映する。
2. **RailsArchitect**: モデル設計／ERD／ルートを PR に添付（Mermaid 推奨）。
3. **RailsCoder**: `feature/<topic>` ブランチを作成し、対応する RSpec を追加する。
4. **TestEngineer**: Model / Request / System spec で正常系・異常系をカバーする。
5. **DevOps**: `bin/ci` で lint / security / test が全てパスすることをマージ条件とする。

**次アクション（短期）**

1. PaperTrail 履歴UIの磨き込み: 変更差分の強調表示、RecipeDay/RecipeStep の復元対応、履歴フィルタの追加。
2. ルーティングの Rails 8.2 キーワード警告解消（routes の hash 引数を keyword 形式へ移行）。
3. スケジューラ設定: 日次サマリ `AuditLogDailySummaryJob` と `AuditLogPruneJob` を本番で定期実行（cron/Heroku Scheduler等）。
4. リリースノート更新: 監査ログ強化・item_id 非表示・日本語ラベル化・最終更新者メール表示をリリース案内に追記。
5. フェーズ5に向けた本番バックアップ計画（DB dump, メンテナンス告知, ロールバック手順）とチェックリスト作成。

---

必要であれば、このファイルをより短い「関係者向けサマリ版」として分割することもできます。どの形式がよいか指示ください。
