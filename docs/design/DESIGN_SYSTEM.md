# TripRecipe — Mini Design System (MVP)

TripRecipe の UI / UX 仕様をまとめたミニデザインシステム。  
Rails 8 + Tailwind CSS による実装を前提とし、  
「実際に行った旅をそのまま真似できる Trip Recipe」を  
見やすく・理解しやすく・再現しやすく表現するための設計方針を定める。

> **MCP遵守**: [AGENTS.md](../../AGENTS.md) に基づき、  
> UI 設計・実装の前に Serena MCP / context7 MCP のリソースを参照すること。

---

# 1. Foundations

TripRecipe の UI は「旅のレシピらしい軽やかさ」と  
「実用ツールとしての読みやすさ」を両立する。  
カラートークンと `tr-*` ユーティリティは `app/assets/tailwind/application.css` で定義されているため、Tailwind 実装時は必ず同ファイルを参照する。

## 1.1 Color System

ブランドキーワード：**爽やか / 実体験 / 信頼感**

| Role              | Token Example (tailwind/application.css) | Notes |
|------------------|-------------------------------------------|-------|
| Primary          | `--color-primary-500 #14b8a6`             | CTA、主要リンク、`tr-primary` / `tr-primary-bg` |
| Primary Light    | `--color-primary-50/100`                  | ホバー背景、淡いチップ |
| Accent           | `--color-accent-500 #fb7185`              | Hero 強調、Tips 内の強い装飾 |
| Secondary Accent | amber-500 / amber-600                     | `Tips Box` や警告ラベル |
| Background       | `--color-bg #fcfbf9` (`tr-bg`)            | ページ背景 |
| Surface          | `--color-surface #ffffff` (`tr-surface`)  | カード、タイムライン |
| Border           | `--color-border-200/300`                  | `tr-border` / `tr-border-strong` で使い分け |
| Text Main        | `--color-text-main #0f172a`               | 本文、見出し |
| Text Sub         | `--color-text-sub #6b7280`                | 補助説明（`tr-text-sub`） |
| Error            | `--color-error #ef4444`                   | フォームエラー文言 |
| Success          | `--color-success #10b981`                 | 保存成功、バッジ |

---

## 1.2 Typography

```
system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI",
"Noto Sans JP", sans-serif
```

| Usage             | Class Example                        | Notes |
|-------------------|----------------------------------------|------|
| Page Title        | text-2xl font-semibold tracking-tight  | 一覧・LP |
| Section Title     | text-xl font-semibold                 | Day セクション |
| Card Title        | text-lg font-semibold                  | レシピカード |
| Body              | text-base leading-relaxed             | 本文 |
| Sub Text          | text-sm text-gray-600                 | 補助情報 |
| Time Label        | text-xs font-medium text-gray-500     | Timeline 時刻 |
| Label             | text-xs uppercase text-gray-500       | 入力ラベル |

---

## 1.3 Spacing

| Element         | Value                     |
|-----------------|---------------------------|
| Page Padding    | px-4 (mobile), px-6 (md+) |
| Section Spacing | py-4〜6                   |
| Component Gap   | space-y-3 / gap-3         |
| Major Gap       | space-y-6                 |
| Card Padding    | p-4                       |

※ Timeline の縦リズムは均一に保つ。

---

## 1.4 Radius & Shadows

- Buttons / Inputs: `rounded-full` or `rounded-lg`
- Cards: `rounded-xl`
- Modals: `rounded-2xl`
- Shadows: `shadow-sm`（基本） / `shadow-md`（強調）

---

# 2. Layout

## 2.1 Container Width

- Mobile: `w-full max-w-md mx-auto`
- Desktop: `max-w-4xl mx-auto`

レシピ詳細は横幅を取り過ぎないようにする。本文と Tips は `max-w-3xl` 以内に収め、左右余白を十分に確保する。

## 2.2 Breakpoints

- モバイルファースト  
- `md:` 以上でレシピカードは 2 カラム

---

# 3. Components

## 3.0 Icons（Heroicons）

- SVG を `app/views/shared/icons/heroicons/outline` に配置
- 呼び出し例：  
  `<%= heroicon("map", classes: "h-4 w-4 text-gray-500") %>`
- Timeline ピンは teal 系 (`bg-primary-500` も可)  
- Tips は amber 系で統一  
- `tr-` 系ユーティリティを優先的に使用し、Tailwind 素の色記法は最小限に抑える

---

## 3.1 Buttons

### Primary Button（CTA / 保存）

```html
<button
  class="inline-flex items-center justify-center px-5 py-2.5 rounded-full
         tr-primary-bg text-white text-sm font-semibold shadow-sm
         tr-primary-hover disabled:opacity-50 disabled:cursor-not-allowed">
  保存する
</button>
```

### Secondary Button（サブアクション）

```html
<button
  class="inline-flex items-center justify-center px-4 py-2 rounded-full
         border tr-border-strong tr-surface text-sm tr-text-main
         hover:bg-gray-50">
  キャンセル
</button>
```

### Ghost Button（アイコンのみ）

```html
<button
  class="inline-flex items-center justify-center p-2 rounded-full
         tr-text-sub hover:bg-gray-100">
</button>
```

---

## 3.2 Form Fields

```html
<label class="block space-y-1">
  <span class="text-xs font-medium text-gray-600">タイトル</span>
  <input
    class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2
           text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
    placeholder="例：3泊4日 ロンドン子連れレシピ" />
</label>
```

エラー：

```html
<p class="text-xs text-red-500 mt-1">タイトルを入力してください。</p>
```

---

## 3.3 Recipe Card

```erb
<article class="flex flex-col rounded-xl border tr-border tr-surface shadow-sm transition hover:tr-border-strong">
  <div class="aspect-video rounded-t-xl bg-gray-100"></div>
  <div class="p-4 space-y-2">
    <p class="flex items-center gap-1 text-xs font-medium uppercase tracking-widest tr-text-sub">
      <%= heroicon("map-pin", classes: "h-3.5 w-3.5") %>
      <span>ロンドン</span>
    </p>
    <h2 class="text-base font-semibold tr-text-main line-clamp-2">
      3泊4日 ロンドン子連れレシピ
    </h2>
    <div class="flex items-center justify-between text-xs tr-text-sub">
      <span>4日間</span>
      <span class="inline-flex items-center gap-1 rounded-full bg-amber-50 px-2 py-0.5 text-amber-700">
        ★ 12
      </span>
    </div>
  </div>
</article>
```

---

## 3.4 Filter Chip

```html
<button
  class="inline-flex items-center px-3 py-1 rounded-full border
         border-gray-300 bg-white text-xs text-gray-700
         hover:bg-gray-50 data-[active=true]:bg-primary-50
         data-[active=true]:border-primary-300 data-[active=true]:text-primary-700">
  子連れ
</button>
```

---

## 3.5 Timeline Item（TripRecipe の中核 UI）

```html
<div class="relative pl-8 space-y-4">
  <div class="absolute left-3 top-1 bottom-1 w-px bg-gray-200"></div>

  <div class="relative flex gap-3">
    <div class="relative z-10 mt-1 h-2 w-2 rounded-full tr-primary-bg"></div>

    <div class="flex-1 space-y-1">
      <p class="text-xs font-medium tr-text-sub">09:00</p>
      <div class="tr-surface border tr-border rounded-lg p-3 shadow-sm">
        <p class="text-sm font-semibold tr-text-main">スポット名</p>
        <a href="#" class="block text-xs tr-primary mt-1">URL</a>
        <p class="text-xs tr-text-sub mt-2">メモや Tips</p>
      </div>
    </div>
  </div>
</div>
```

---

## 3.6 Tips Box

```html
<div class="mt-3 rounded-lg bg-amber-50 border border-amber-100 p-3">
  <p class="text-xs font-semibold text-amber-800 mb-1">Tips</p>
  <p class="text-xs text-amber-900">
    子どもが途中で疲れやすいので休憩ポイントを事前に確認。
  </p>
</div>
```

---

# 4. Feedback

## 4.1 Error Box

```html
<div class="mb-4 rounded-md border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
  入力内容を確認してください。
</div>
```

## 4.2 Empty State

- Icon（Heroicons）
- 説明文（短く）
- CTA ボタン

## 4.3 Loading

- ボタンを disabled  
- スピナーは最小限

---

# 5. Versioning

- Version: 1.1 (TripRecipe Brand Edition)
- 更新方針：プロダクトフェーズに合わせて最小限拡張
