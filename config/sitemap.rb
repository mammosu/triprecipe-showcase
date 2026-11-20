# frozen_string_literal: true

require "sitemap_generator"

SitemapGenerator::Sitemap.default_host = ENV.fetch("SITEMAP_HOST", "https://triprecipe.app")
SitemapGenerator::Sitemap.public_path = ENV.fetch("SITEMAP_PUBLIC_PATH", Rails.root.join("public").to_s)
SitemapGenerator::Sitemap.sitemaps_path = ENV.fetch("SITEMAP_PATH", "")
SitemapGenerator::Sitemap.compress = :all_but_first

SitemapGenerator::Sitemap.create(
  create_index: :auto,
  include_root: false,
  verbose: ENV["SITEMAP_VERBOSE"] == "1"
) do
  url_helpers = Rails.application.routes.url_helpers

  add url_helpers.root_path, changefreq: "daily", priority: 1.0

  if url_helpers.respond_to?(:recipes_path)
    latest_recipe_update = Recipe.where(public: true).maximum(:updated_at)
    if latest_recipe_update
      add url_helpers.recipes_path,
          changefreq: "daily",
          priority: 0.8,
          lastmod: latest_recipe_update
    else
      add url_helpers.recipes_path, changefreq: "daily", priority: 0.8
    end
  end

  static_helpers = %i[about_path terms_path privacy_path faq_path]
  static_helpers.each do |helper|
    next unless url_helpers.respond_to?(helper)

    add url_helpers.public_send(helper), changefreq: "yearly", priority: 0.3
  end

  Recipe.where(public: true).select(:id, :slug, :updated_at).find_each(batch_size: 1000) do |recipe|
    add url_helpers.recipe_path(recipe),
        lastmod: recipe.updated_at,
        changefreq: "weekly",
        priority: 0.7
  end
end

# NOTE:
# - Fly.io の root filesystem は通常エフェメラルです。永続化が必要なら volume を使うか、
#   deploy/cron で生成し直す運用にしてください。
# - Cloudflare 等の CDN を使う場合、/sitemap* のキャッシュを更新後に purge する運用が安全です。
