## 概要
RecipeDay の上に RecipeStep を追加し、1 日を複数のアクティビティで構成できるようにする。Phase 2 の仕様は `docs/phases/phase2_recipe_step.md` を参照。

## ToDo / DoD
- [ ] `recipe_steps` テーブル追加、モデル実装、RecipeDay/Recipe の関連付け。
- [ ] RecipeStep CRUD（新規・編集・削除）UI と時間順リスト。
- `docs/phases/phase2_recipe_step.md`
- `docs/roadmap/ROADMAP.md`
## 状態: 完了

- 完了日: 2025-12-17
- 備考: 実装（モデル・マイグレーション・コントローラ・ビュー）と Request/Model の spec が存在し、`db/schema.rb` に `recipe_steps` テーブルが定義されています。関連ドキュメントは `docs/phases/phase2_recipe_step.md` に移行され、バックアップは `docs/backup/` に保存しています。

## 概要
RecipeDay の上に RecipeStep を追加し、1 日を複数のアクティビティで構成できるようにする。Phase 2 の仕様は `docs/phases/phase2_recipe_step.md` を参照。

## ToDo / DoD
- [x] `recipe_steps` テーブル追加、モデル実装、RecipeDay/Recipe の関連付け。
- [x] RecipeStep CRUD（新規・編集・削除）UI と時間順リスト。
- [x] position の自動採番と簡易並び替えボタン。
- [x] Model + Request spec 追加、`bundle exec rspec` / `bundle exec rubocop -f github` パス。
- [x] ドキュメント更新（README、ROADMAP）。

## 参考
- `docs/phases/phase2_recipe_step.md`

```
