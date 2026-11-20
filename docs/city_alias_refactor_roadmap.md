# CityAliasリファクタ リセット前提ロードマップ

目的: DBリセット可能なタイミングで都市正規化をシンプルかつ堅牢に再構成する。JSON aliasesを廃止し、CityAliasテーブル一本化で検索・同期を明快にする。

## ステップ概要
- 0. 前提確認: `db:reset`実施可、現行データのバックアップ不要を合意。
- 1. スキーマ再設計
  - cities: `name_ja`, `name_en`, `country_code(2)`, `slug`(unique, not null) のみ。
  - city_aliases: `city_id`(FK cascade), `raw_name`, `normalized_name`(unique), `locale`(nullable, 将来用)。
  - recipes: `city_display`, `city_id`は現行維持。
- 2. マイグレーション実装
  - drop/recreate `city_aliases` (unique: normalized_name)。
  - remove_column `cities.aliases`。
  - add indexes: `city_aliases.normalized_name`, `city_aliases.city_id`.
- 3. モデル実装
  - City: `has_many :city_aliases, dependent: :destroy`, `accepts_nested_attributes_for` を許容。
  - CityNormalizer: 現行流用。
  - match_by_alias/autocomplete は CityAlias JOIN のみに統一。
  - コールバック同期削除（明示的に CityAlias を保存）。
- 4. シード・Factory刷新
  - db/seeds.rb: City + CityAlias を attributes で投入（JSON配列変換ロジック削除）。
  - FactoryBot city: after(:create) で複数 alias 生成。
- 5. アプリ調整
  - City選択UI/Controller/Services は CityAlias 前提でも現行APIインターフェース維持。
  - Docs更新（WIDE_AREA_RECIPES 等）。
- 6. テスト更新
  - City周りのRSpecを CityAlias 前提に書き換え。
  - seeds/factoriesに合わせて期待値修正。
- 7. 実行
  - `bin/rails db:reset db:seed`
  - `bundle exec rspec`
- 8. フォローアップ
  - 必要なら city_aliases.locale/kind 追加検討。
  - FTS/トライグラム等の高速化は次フェーズで判断。

## リスクと対応
- 既存データ消失: リセット実施前に現行環境バックアップの要否を再確認。
- エイリアス重複: normalized_name uniqueで弾く。衝突時は seeds 修正。
- UI互換性: APIレスポンス形は不変に保つため既存フロント影響は最小。

## 完了条件 (DoD)
- マイグレーションがクリーンに通り、`cities` から `aliases` カラムが消える。
- City/CityAlias モデル経由で `match_by_alias`, `autocomplete` が動作し、RSpec グリーン。
- seeds が新スキーマで投入可能。
- docs に手順と仕様差分が反映される。
