## タイトル
Phase 3.5: SavedRecipes 発見導線の強化

## 概要
公開レシピの「人気」「最近のお気に入り」を Surfacing し、他ユーザーの Recipe 発見率を高める。カードへのお気に入り数表示と、おすすめセクション（例: 人気レシピ top5）を MVP とする。

## 目的 / KPI
- Recipe 一覧におけるおすすめ表示の CTR 向上。
- 少なくとも 1 件の他ユーザー公開レシピをお気に入り登録するユーザー割合を 20%→30% へ。

## タスク（案）
- [x] 集計要件: 直近30日のお気に入り数を集計する SQL / scope を定義し、private recipe を除外する。
- [x] UI: `Recipes#index` に「人気のレシピ」カードセクションを追加。カード内に `favorite_count` バッジを表示。
- [x] 再訪導線: SavedRecipes が 0 件の場合の空状態コピー、1 件以上の場合の「最近のお気に入り」セクションを追加。
- [x] Request spec: 発見セクションのAPI/HTMLレスポンスで非公開レシピが混入しないことを検証。
- [x] README/ROADMAP/phase3 docs を更新し、Phase 3.5 の位置付けを明文化。

## DoD
- `bundle exec rspec` / `bundle exec rubocop -f github` がローカルで成功。
- Recipes#index におすすめカードが表示され、fixture でお気に入り数が反映される画面キャプチャを PR に添付。
- 新旧の UI/UX 変更点を docs/phases/phase3_favorite.md に追記済み。
- GitHub Issue で関連 PR を `Fixes #<issue>` として紐づけ。

## 参考
- `docs/phases/phase3_favorite.md` > Phase 3.5 セクション
- 既存 SavedRecipes 実装 (`Recipe.visible_to`, `SavedRecipesController#index`)
