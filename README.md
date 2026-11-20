# TripRecipe

**Create, share, and collaborate on travel itineraries you can actually follow.**

[Live website](https://triprecipe.app) · [Architecture](docs/architecture/PROJECT_OVERVIEW.md) · [Development roadmap](docs/roadmap/ROADMAP.md)

TripRecipe is a full-stack Ruby on Rails application for turning real trips into reusable travel plans. An itinerary consists of a **Recipe**, its ordered **Days**, and time-based **RecipeSteps**. Users can explore public recipes, save favorites, and manage their own plans.

> **日本語:** 実際に訪れた旅程を日別・時系列の「旅のレシピ」として記録・共有できるWebアプリです。認証、権限管理、共同編集、履歴・監査などをRailsで実装しています。
>
> **Español:** Aplicación web para crear, compartir y editar itinerarios de viaje organizados por días y actividades.

## Features

- **Travel itinerary management:** Create, update, publish, and privately manage recipes with days and ordered activities.
- **Discovery:** Browse and filter recipes using destinations, tags, and keywords; save favorites.
- **Collaboration:** Invite collaborators with `viewer`, `editor`, and `admin` roles. Authorization is enforced through Pundit policies.
- **Controlled sharing:** Share-token links, expiry rules, and access records for selected itineraries.
- **History and accountability:** Audit logs, revision history, and event tracking for important actions.
- **Content management:** Image uploads for recipes and itinerary steps, plus an admin interface with Avo.
- **SEO and moderation:** Slug-based URLs, metadata, sitemap support, and reporting workflows.

## Technical highlights

| Area | Implementation |
| --- | --- |
| Framework | Ruby 3.4.1, Rails 8.1, Hotwire (Turbo / Stimulus), importmap |
| UI | ERB, Tailwind CSS |
| Authentication / authorization | Devise, Pundit, role-based collaboration |
| Persistence | SQLite with separate production databases for primary, cache, queue, and cable |
| Background processing | Solid Queue, Solid Cache, Solid Cable |
| File storage | Active Storage; Cloudflare R2 in production |
| Administration | Avo |
| Quality tooling | RSpec, Capybara, FactoryBot, RuboCop, Brakeman, Bundler Audit |
| Development environment | VS Code Dev Containers |

### Design considerations

- **Authorization at the resource level:** `app/policies/recipe_policy.rb` distinguishes owners, collaborators, public viewers, and share-link access.
- **Separation of responsibilities:** Service objects handle operations such as recipe forking, slug management, and image handling.
- **Traceability:** Audit history and application events serve different purposes.
- **Operations:** CI runs the test suite, linting, and dependency checks.

For design decisions and planned work, see [project documentation](docs/README.md). Documentation about future phases should not be assumed to describe functionality already deployed.

## Local development

Prerequisites: Ruby 3.4.1, Bundler, and SQLite. See `.ruby-version` and `Gemfile` for the maintained versions.

```bash
git clone https://github.com/mammosu/triprecipe-showcase.git
cd triprecipe-showcase
bin/setup --skip-server
bin/dev
```

Open [http://localhost:3000](http://localhost:3000). Development seed data is intended for local use only; do not treat sample accounts or their passwords as production credentials.

Local development uses disk storage and can run without production credentials or an `.env` file. You can also open the project in VS Code with **Dev Containers: Reopen in Container**.

## Tests and security checks

```bash
bundle exec rspec
bin/rubocop -f github
bin/brakeman --no-pager
bin/bundler-audit
bin/importmap audit
```

GitHub Actions defines linting, security scans, RSpec tests, and system tests. A configured check does **not** itself guarantee a passing run; refer to the actual Actions results.

## Portfolio snapshot

This repository contains a snapshot of TripRecipe prepared for portfolio review. The live demo is available at [triprecipe.app](https://triprecipe.app).

The project source is presented for review. Third-party materials retain their respective licenses.
