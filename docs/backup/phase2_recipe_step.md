# Phase 2: RecipeStep 行動詳細

RecipeDay の上に時間軸を載せ、1 日を複数アクティビティで構成できるようにするフェーズ。ProductPlannerAgent / RailsArchitectAgent / RailsCoderAgent / TestEngineerAgent が同じ仕様を参照できるよう整理する。

## 🎯 目的 / ユースケース
- 各 RecipeDay に「朝食」「移動」「観光」など 1 時間単位で行程を登録し、時間順に表示したい。
- 子連れ/シニア向けに無理のない移動計画を立てるため、開始/終了時刻の整合性を自動チェックしたい。
- 将来的にカテゴリ別アイコン表示やドラッグ並び替えを実装できるよう、position フィールドを準備する。

## ✅ DoD
- [x] `recipe_steps` テーブル追加 + モデル実装 (`RecipeStep`)。
  - NOT NULL: `recipe_day_id`, `title`, `starts_at`, `position`。
  - CHECK: `ends_at IS NULL OR ends_at >= starts_at`。
  - `position` は RecipeDay 内で一意。
- [x] `RecipeDay has_many :recipe_steps, -> { order(:position) }, dependent: :destroy`。
- [x] `RecipeStepsController`（create/update/destroy）と `app/views/recipes/show.html.erb` で UI を反映。
- [x] Recipe 詳細ページで RecipeDay 毎に RecipeStep を時間順に表示。
- [x] 最小限の並び替え（position を +1/-1 するボタン）を提供。ドラッグは Phase 2.5 backlog。
- [x] RSpec: RecipeStep model spec（バリデーション、自動 position 採番）、request spec（create/update/destroy、認可）。
- [x] README / ROADMAP / docs 更新済み、Issue 作成済み。

## 🧱 データモデル案
```mermaid
erDiagram
  recipes ||--o{ recipe_days : has
  recipe_days ||--o{ recipe_steps : has

  recipe_steps {
    integer id PK
    integer recipe_day_id FK
    integer position
    string title
    string category
    time starts_at
    time ends_at
    text notes
    timestamps
  }
```

### バリデーション
- `title`: presence, length ≤ 100。
- `starts_at`: presence。
- `ends_at`: optional, must be ≥ `starts_at` when present。
- `position`: integer ≥1, unique per `recipe_day_id`。
- `category`: optional enum (e.g., `:food, :move, :activity, :stay, :other`)。Enum 定義で i18n 対応。
- `notes`: ≤ 2000 文字。

### コールバック
- `before_validation` で `position` 未指定なら `recipe_day.recipe_steps.maximum(:position).to_i + 1`。

## 🔁 ルーティング
```rb
resources :recipes do
  resources :recipe_days, except: :index do
    resources :recipe_steps, except: :index do
      member do
        post :move_up
        post :move_down
      end
    end
  end
end
```

## 🛠 コントローラ指針
- 認可: `RecipeScoped` をベースに、`set_recipe_day` + `authorize_owner!(@recipe)` を再利用。
- Strong params: `:title, :category, :starts_at, :ends_at, :notes, :position`。
- JSON/Turbo Stream への拡張余地を残しつつ、まずは HTML レスポンスで MVP。

## 🧑‍🎨 UI/UX
- Recipe show の各 RecipeDay カード内にタイムラインリストを表示。
- タイムライン項目: 時刻 + カテゴリ pill + タイトル + ノート。
- CTA: 「＋ 行動を追加」ボタン（オーナーのみ）。
- 並び替え: 各カード右側に「▲」「▼」ボタン。

## 📋 タスク分解
1. **Schema**: migration・model 追加 + spec。
2. **Association**: RecipeDay モデルに `has_many :recipe_steps`、Recipe に `has_many :recipe_steps, through: :recipe_days` (任意)。
3. **Controller**: `RecipeStepsController` + strong params + position helper。
4. **Views**: partial (`_recipe_step`, `_timeline_form`) を作り RecipeDay カードへレンダリング。
5. **Ordering helper**: service/concern で `move_up!` / `move_down!` を実装し再利用。
6. **Specs**: model + request。将来の System Spec は backlog。
7. **Docs**: README、ROADMAP、Issue 連携。

## 📌 リスク / メモ
- `starts_on` + `starts_at` の組み合わせで日付跨ぎ行程が必要になる可能性 → Phase 2 では同一日のみ想定。
- 並び替えは race condition が起き得るため、将来的に `acts_as_list` など検討。
- API レスポンス拡張を見越して Presenter/Decorator で JSON 化できるよう設計。

## 🔜 次アクション
1. Phase 3 (お気に入り機能) の要件を `docs/ROADMAP.md` に沿って詳細化。
2. RecipeStep 並び替え UI をドラッグ&ドロップへ拡張する backlog を作成。
3. Recipe API 化や共有リンクなど Phase 4 に向けた調査を開始。
