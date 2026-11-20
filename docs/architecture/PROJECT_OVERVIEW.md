# PROJECT_OVERVIEW

> **MCP遵守**: すべての作業は [AGENTS.md](../../AGENTS.md) の共通ルールに従い、着手前に Serena MCP と context7 MCP のリソースを確認してください。

## TripRecipe — プロジェクト概要

> **Real trip recipes you can actually follow.**  
> TripRecipe は、実際に行った旅を「そのまま真似できる旅のレシピ」として整理・共有するための Rails 8 製 MVP です。

SNS の写真だけでは分からない、**現実的で再現性のある旅程情報**を扱うことで、  
旅行者が「無理なく回れる計画」を素早く組み立てられる体験を提供します。

---

## 1. プロダクトミッション

TripRecipe は、旅行者が体験した **日別・時系列のリアルな旅程（Trip Recipe）** を  
テンプレートとして共有し、他の旅行者がそのまま真似できる状態をつくることを目的とします。

特に以下の旅行課題を解決します：

- SNS は写真中心で **実際に回れる順序** が分からない  
- 子連れ・家族旅行では **体力や動線を考えた旅程** を探しにくい  
- AI プランは平均的で、**現地のリアル（混雑・疲労度・休憩ポイント等）** が不足している  
- スプレッドシート管理は **共有・再利用しづらい**

TripRecipe は、Recipe / RecipeDay / RecipeStep を軸に  
「**見て分かる・真似して使える**」旅程テンプレートを構築します。

---

## 2. 主要ペルソナ

- **週末旅行・連休旅行を効率よく計画したい 20〜40代のカップル・ファミリー**
- **複数都市の旅程を Notion やスプレッドシートから移したいライトプランナー**
- **公開レシピを参考にし、自分用にコピーしたい旅行好きコミュニティ**
- **旅ログ / 旅レシピを綺麗な形で残したい投稿ユーザー**

---

## 3. MVP 範囲（スコープ）

MVP では、TripRecipe の「核となる体験」を最短で届けるために、以下を実装します。

### 1. **Recipe**
- タイトル / 都市 / 日数 / 説明文
- 公開・非公開設定
- slug ベースの共有 URL（`https://triprecipe.app/recipes/:slug`）
- 投稿者名の表示（簡易プロフィール）

### 2. **RecipeDay**
- 1 日単位での行程管理
- 並び順（1 → n 日）の固定
- 簡易メモ（当日の補足情報）

### 3. **RecipeStep**
- 各日の行動を **時刻順** に整理
- URL（地図リンク等）
- Tips（現地のリアル情報）
- 並び順管理（時刻ベース）

### 4. **SavedRecipe**
- 公開レシピのお気に入り登録
- ユーザーの「保存リスト」
- 人気レシピの軽いディスカバリー指標

### 5. **RecipeShareToken / SEO**
- 限定公開リンク（RecipeShareToken）による一時的共有と参照ログ（RecipeShareAccessLog）
- OGP / meta テンプレート（タイトル / 都市 / 日数 / サムネイル）を `ApplicationHelper` で一元管理

### 6. **Collaboration & Access Control**
- `RecipeCollaborator` による viewer / editor / admin の 3 段階ロール
- Pundit (`RecipePolicy`) を用いた所有者 / コラボレーター / 共有リンクアクセスの統合認可
- コラボレーター管理 UI（招待・承認/辞退・ロール変更・削除）
- 共有リンクの延長 / 再発行 / 無効化をワンクリックで行える管理パネル

---

## 4. ノンゴール（MVPでやらないこと）

- Google Maps の高度な地図 UI 連動  
- ホテル/フライトの自動取り込み  
- AI 旅程生成  
- 課金（PDF 販売 / マーケットプレイス）  
- 旅程コピー機能（Phase 2 予定）  
- リアルタイム共同編集・コメント・ワークフロー管理  
- モバイルアプリ  

---

## 5. 技術スタックサマリ

**言語 / フレームワーク**
- Ruby 3.4.1
- Rails 8.1（Turbo / Stimulus / importmap）

**フロントエンド**
- Tailwind CSS（Design System に基づくトークン設計）

**認証 / 認可**
- Devise（Email / Password）
- Pundit（Policy ベースのロール管理）

**データベース**
- SQLite3（開発・本番・テストで統一）

**テスト**
- RSpec + Capybara  
- RuboCop Rails Omakase

**Rails 8 機能検証**
- Solid Cache
- Solid Queue
- Solid Cable

**デプロイ想定**
- Fly.io / Render  
- カスタムドメイン：`https://triprecipe.app`

---

## 6. フェーズ別ロードマップ（要約）

### **Phase 0**（完了）
- Recipe / Day / RecipeStep の CRUD
- Devise 認証
- 最低限の一覧・詳細 UI

### **Phase 1**（完了）
- お気に入り（SavedRecipe）
- 検索（都市・日数・キーワード）
- OGP / SEO
- レシピ共有導線の改善

### **Phase 2**（完了）
- 旅程コピー機能（Duplicate / Fork）
- タグ管理
- 投稿者プロフィール
- UX 改善（モバイル最適化）

### **Phase 3**（完了）
- 旅のレシピ PDF 出力
- 旅程販売マーケットプレイス構想（検討）

### **Phase 3.5**（完了）
- Recipes#index に「人気のレシピ」セクションとお気に入りバッジを表示
- SavedRecipes#index の空状態コピー強化、お気に入り数の 30 日集計 scope を追加

### **Phase 4**（完了）
- slug ベース URL・限定公開リンク（RecipeShareToken）・アクセスログを実装
- Pundit + RecipeCollaborator による共同編集
- meta / OGP（`seo_page_title`, `seo_meta_description`）テンプレート適用
- 2025-12-19 時点: Phase 4 の機能実装完了。共有リンク運用と監査ログの整備も反映済み。

### **Phase 4.5**（完了）
- PaperTrail による履歴記録（Recipe / RecipeDay / RecipeStep）
- 履歴 UI（一覧/詳細）と Recipe の基本復元機能

---

## 7. 参考ドキュメント

- [SCREENS_MVP](../design/SCREENS_MVP.md)
- [DESIGN_SYSTEM](../design/DESIGN_SYSTEM.md)
- [ROADMAP](../roadmap/ROADMAP.md)
- [phase1_recipe_day](../phases/phase1_recipe_day.md)
- [phase2_recipe_step](../phases/phase2_recipe_step.md)
- [phase3_favorite](../phases/phase3_favorite.md)
- [phase4_collaboration](../phases/phase4_collaboration.md)

各ドキュメントでも Serena MCP / context7 MCP を参照し、  
常に最新のリソースを利用できる状態を維持してください。
