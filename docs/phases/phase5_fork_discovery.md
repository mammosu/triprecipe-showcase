# Phase 5 Spec: Fork（コピー）+ Discovery（発見性）+ Trust & Safety（通報運用）
TripRecipe / Next Phase（MVP志向）仕様書

> 参照: `PROJECT_OVERVIEW.md`, `SCREENS_MVP.md`（既存のMVP画面/遷移・思想を尊重）  
> 技術前提: Rails 8.1 / SQLite / Devise / Pundit / RSpec / Hotwire / Tailwind / Pagy  
> 直近仕様: Recipe URL は slug のみ（数値IDは404）

---

## 0. このフェーズの狙い（MVP）
**「気に入った公開レシピを自分用にコピーして編集し、再共有できる」**を最短で成立させる。  
同時に、Forkによって増えるリスク（盗用/スパム）を**“最小運用コスト”で抑える**。

### 成功状態（定性的）
- 公開レシピ詳細から「ベースにして作る」が迷わず使える
- 保存一覧（Saved）からもコピーして自分用にカスタムできる
- タグで最低限“探せる”
- 通報ができ、管理側が対応できる（Avoで手動運用）

---

## 1. スコープ
### MUST
- 公開レシピのFork（複製）機能
- Fork導線（レシピ詳細・保存一覧）
- タグ（固定候補 or フリーテキスト最小）での絞り込み
- 通報（report）+ Avoでの対応（非公開化/削除の運用導線）
- パフォーマンス最低限（N+1回避、主要ページのクエリ確認）

### SHOULD
- 公開プロフィール（作者の他レシピ導線）
- 検索の改善（タグ + 都市 + 並び替え）

### WON’T（このPhaseではやらない）
- 課金、AI生成、地図の本格UI、コメント、リアルタイム同時編集

---

## 2. ユースケース（ユーザーストーリー）
### US1: Fork（コピー）
ユーザーとして、公開レシピを自分のレシピとしてコピーし、編集を開始したい。  
- 受け入れ条件:
  - コピー後は自分が owner の下書きレシピになる
  - Day/Step の並び順が保持される
  - コピー完了後に「編集画面 or 新しいレシピ詳細」に遷移する

### US2: Attribution（コピー元表示）
ユーザーとして、コピー元が分かるようにしたい（信頼/マナー）。  
- 受け入れ条件:
  - コピー先レシピに「元レシピ」へのリンクが表示される（公開時のみリンク）
  - 元レシピが非公開/削除のときはリンク無効（テキストのみ等）

### US3: SavedからFork
ユーザーとして、保存したレシピをベースに自分用に作りたい。  
- 受け入れ条件:
  - SavedRecipes#index に「コピー」導線
  - 権限/公開条件の制約に従う

### US4: タグで探す
ユーザーとして、タグで自分に合うレシピを絞り込みたい。  
- 受け入れ条件:
  - recipes#index でタグ絞り込み
  - レシピカードにタグを最大2〜3個表示

### US5: 通報
ユーザーとして、不適切な公開レシピを通報したい。  
- 受け入れ条件:
  - 公開レシピ詳細に「通報」導線
  - 理由 + 任意コメント
  - 同一ユーザーが同一レシピを連打しても重複作成されない（最小防止）

---

## 3. 仕様詳細

### 3.1 Fork（複製）仕様
#### Fork可能条件（MVP）
- **ログインユーザーのみ**
- 対象は **公開レシピのみ**（share token 経由閲覧はMVPではFork不可）
- 自分が閲覧できる（Punditでshow可能）かつ `recipe.public?` のときだけ

#### Forkで複製する範囲
- Recipe（title, description, city, days構造、公開状態はコピー先では強制「非公開」推奨）
- RecipeDay（順序含む）
- RecipeStep（順序、本文、時刻、URL等の属性）
- 写真（RecipeStepのPhotos）は **方針を選択**：
  - MVP推奨: **ActiveStorage blob 共有**（同じ画像を参照し直す）
  - 注意: purge（物理削除）運用だと共有に影響が出るため、原則は参照カウントではなく「所有者削除＝attach解除のみ」に寄せる

#### slug の生成
- コピー先は新規slugが必須
- 例ルール:
  - `"#{original.slug}-copy"` をベースに重複時は `-2`, `-3` を付与
  - 文字数制限や予約語がある場合は既存slug生成器に統合

#### Audit/Version
- 既存の監査ログ/バージョン仕組みに統合できるなら
  - event: `fork`
  - metadata: `{ forked_from_recipe_id: x, forked_from_slug: y }`
- Forkで生成される RecipeDay / RecipeStep の監査ログはノイズになりやすいため、
  **ユーザー向け履歴では「コピー」1件のみ表示**される設計を推奨

---

### 3.2 Tag（タグ）仕様
#### MVP方針（おすすめ）
- **固定候補タグ（チェックボックス）**にする
  - 入力バリデーション/スパム耐性/運用容易性が高い
- 候補例（後で見直し可）:
  - `family`（子連れ）
  - `rainy`（雨の日）
  - `budget`（節約）
  - `walkable`（徒歩中心）
  - `museum`（美術館・博物館）
  - `food`（グルメ中心）
  - `short`（半日/日帰り）

#### 表示
- recipes#index のカードで最大3つ（溢れは `+2` 表記など）

#### 絞り込み
- `?tag=family` でフィルタ
- `?tags[]=family&tags[]=food` の AND/OR はMVPでは **OR** 推奨（見つかりやすい）
  - ANDは次フェーズでもよい

---

### 3.3 Report（通報）仕様
#### 通報対象
- 公開レシピのみ（非公開は通報導線を出さない）
- 通報理由（enum）
  - `spam`
  - `copyright`
  - `hate`
  - `adult`
  - `other`

#### 二重通報防止（MVP）
- `user_id + recipe_id` で1件まで
- 再通報は「更新」扱い（コメント上書き or 追記）どちらでも良いがMVPは上書きでOK

#### 管理運用（Avo）
- Report一覧
  - status: `open`, `reviewing`, `resolved`, `dismissed`
- 対応アクション（手動）
  - レシピを非公開にする（最重要）
  - 通報を resolved/dismissed に変更

---

## 4. データモデル（提案）

### 4.1 Fork用
- `recipes.forked_from_recipe_id`（nullable, index）
  - 自己参照（元レシピ）
- （任意）`recipes.forked_from_user_id`（元作者を固定したい場合）
  - 元レシピが削除されても attribution だけ残せる
  - MVPでは `forked_from_recipe_id` のみでも可

### 4.2 Tag用
- `tags` テーブル
  - `key`（ユニーク: `family` 等）
  - `label_ja`（表示名: `子連れ` 等）
- `recipe_tags` テーブル（join）
  - `recipe_id`, `tag_id`（複合ユニーク）

### 4.3 Report用
- `recipe_reports`
  - `recipe_id`, `user_id`
  - `reason`（enum）
  - `comment`（nullable）
  - `status`（enum, default: open）
  - `handled_by_user_id`（nullable）
  - timestamps
  - `index (user_id, recipe_id) unique`

---

## 5. ルーティング/コントローラ（提案）
### 5.1 Fork
- `POST /recipes/:recipe_id/forks`（or `member do post :fork end`）
  - RESTっぽくするなら `resources :forks, only: :create, controller: "recipes/forks"` を member に

例:
```ruby
resources :recipes do
  post :fork, on: :member
end
```

### 5.2 Tag絞り込み
- 既存 `recipes#index` に `params[:tag]` / `params[:tags]` 対応

### 5.3 Report
- `POST /recipes/:recipe_id/report`
- `GET /recipes/:recipe_id/report/new`（モーダルで済ませるなら不要）

---

## 6. Pundit（権限）設計（提案）
### Fork
- `RecipePolicy#fork?`
  - user.present?
  - record.public?
  - record.show? 相当（すでに show? があれば併用）

### Tag編集
- 既存の `update?`（owner/editor/admin）でOK

### Report
- `RecipeReportPolicy#create?`
  - user.present?
  - recipe.public?

---

## 7. UI/画面仕様（最小）
### 7.1 Recipe詳細（recipes#show）
- 既存 CTA 群に追加:
  - primary: 「このレシピをベースに作る」
- attribution 表示:
  - `forked_from_recipe_id` があれば
    - 「元レシピ: {title}」リンク（元が公開ならリンク有効）

### 7.2 SavedRecipes#index
- 各カードに「コピー」ボタン（公開レシピのみ）

### 7.3 recipes#index
- タグフィルタ（chips or select）
- カードにタグ表示（最大3）

### 7.4 通報UI
- 公開レシピ詳細に「通報」
- モーダル（Turbo Frame）で理由選択 + コメント
- 送信後は toast/flash で完了表示

---

## 8. 実装方針（サービス/トランザクション）
Forkはサービスオブジェクトで単一責務化（複製バグを減らす）。

例（概念）:
```ruby
class RecipeForkService
  def initialize(user:, recipe:)
    @user = user
    @recipe = recipe
  end

  def call
    raise Pundit::NotAuthorizedError unless RecipePolicy.new(@user, @recipe).fork?

    Recipe.transaction do
      new_recipe = duplicate_recipe!
      duplicate_days_and_steps!(new_recipe)
      duplicate_photos!(new_recipe) # blob共有 or 複製方針に従う
      new_recipe
    end
  end
end
```

---

## 9. テスト（RSpec）DoD
### Fork
- model/service spec
  - 複製後の件数一致（days/steps）
  - 並び順維持（position等）
  - forked_from_recipe_id がセットされる
  - slugがユニークになる
- request spec
  - 未ログインは403/リダイレクト
  - 非公開レシピは不可
- system spec（最小）
  - 公開レシピ詳細 → コピー → コピー先で編集開始ができる

### Tag
- request spec
  - `recipes#index?tag=family` で絞り込みされる
- system spec（任意）
  - フィルタ操作で結果が変わる

### Report
- request spec
  - 同一user+recipeで2回投げても1件（更新）になる
- policy spec
  - 非公開レシピは通報不可

---

## 10. パフォーマンス/運用（DoD）
- recipes#index, recipes#show, saved_recipes#index で N+1 がない（includesで解決）
- Pagy 維持
- Avo で `recipe_reports` を確認・対応できる
- docs追記:
  - Fork仕様（公開条件、写真方針、slugルール）
  - Report運用（対応フロー）

---

## 11. リリース手順（段階的）
### Step 1: Fork（テキストのみ）
- Day/Step複製 + slug生成 + attribution表示

### Step 2: Fork導線拡充
- Savedからコピー
- エラー/権限制御整備

### Step 3: 写真対応
- blob共有 or 複製の実装確定

### Step 4: タグ
- 固定タグ + recipes#index絞り込み

### Step 5: 通報 + Avo
- report UI + Avo resource + 運用手順 docs

---

## 12. 未確定事項（仮定の明示）
- 写真の複製方針は「blob共有」を推奨として記載（運用ポリシー次第で変更）
- share token 経由閲覧の fork は Phase 6 以降（MVPでは禁止）
- タグは固定候補想定（フリーテキストは次以降）

---
