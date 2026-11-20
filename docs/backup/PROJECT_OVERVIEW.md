# PROJECT_OVERVIEW

> **MCP遵守**: すべての作業は [AGENTS.md](../../AGENTS.md) の共通ルールに従い、着手前に Serena MCP と context7 MCP のリソースを確認してください。

# TripRecipe — プロジェクト概要

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
- **公開プランを参考にし、自分用にコピーしたい旅行好きコミュニティ**
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
- 公開プランのお気に入り登録
- ユーザーの「保存リスト」
- 人気プランの軽いディスカバリー指標

### 5. **RecipeShareToken / SEO**
This document has been reorganized.

Please see [docs/architecture/PROJECT_OVERVIEW.md](../architecture/PROJECT_OVERVIEW.md) for the canonical project overview.
### 6. **Collaboration & Access Control**
