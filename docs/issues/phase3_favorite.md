## 概要
公開 Recipe をお気に入り登録できるようにし、再訪導線とギャラリー発見性を強化する。詳細仕様は `docs/phases/phase3_favorite.md` を参照。

## ToDo / DoD

## 参考
```markdown
## 状態: 完了

- 完了日: 2025-12-17
- 備考: 実装とテストが完了し、関連ドキュメントは `docs/phases/phase3_favorite.md` に移行されています。バックアップは `docs/backup/` に保存されています。

## 概要
公開 Recipe をお気に入り登録できるようにし、再訪導線とギャラリー発見性を強化する。詳細仕様は `docs/phases/phase3_favorite.md` を参照。

## ToDo / DoD
- [x] `favorites` テーブル + `SavedRecipe` モデル追加、user/recipe との関連を定義（複合 UNIQUE）。
- [x] `SavedRecipesController#index`（ログイン必須）で自分のお気に入りをカード表示。
- [x] `resource :favorite` を recipes にネストし、登録/解除エンドポイントを実装。
- [x] Recipe show/index にボタン・お気に入り一覧 UI を追加。
- [x] Model + Request spec を追加、`bundle exec rspec` / `bundle exec rubocop -f github` が成功すること。
- [x] README / ROADMAP / docs 更新。

## 参考
- `docs/phases/phase3_favorite.md`

```
