# frozen_string_literal: true

require "rails_helper"
require "fileutils"
require "rexml/document"
require "sitemap_generator"

RSpec.describe "Sitemap generation" do
  let(:tmp_path) { Rails.root.join("tmp/sitemaps_test") }

  around do |example|
    original_env = ENV.to_h
    FileUtils.rm_rf(tmp_path)
    FileUtils.mkdir_p(tmp_path)
    ENV["SITEMAP_PUBLIC_PATH"] = tmp_path.to_s
    ENV["SITEMAP_PATH"] = ""
    ENV["SITEMAP_HOST"] = "https://triprecipe.app"
    ENV["SITEMAP_VERBOSE"] = "0"
    example.run
  ensure
    FileUtils.rm_rf(tmp_path)
    ENV.replace(original_env)
  end

  def read_sitemap
    File.read(tmp_path.join("sitemap.xml"))
  end

  it "includes only public recipes and excludes share urls" do
    public_recipe = create(:recipe, public: true, slug: "public-recipe", updated_at: 2.days.ago)
    create(:recipe, public: false, slug: "private-recipe")

    load Rails.root.join("config/sitemap.rb")

    xml = read_sitemap
    expect(xml).to include("/recipes/#{public_recipe.slug}")
    expect(xml).not_to include("/recipes/private-recipe")
    expect(xml).not_to include("/share/")
  end

  it "generates valid xml" do
    create(:recipe, public: true, slug: "valid-recipe", updated_at: Time.current)

    load Rails.root.join("config/sitemap.rb")

    xml = read_sitemap
    expect { REXML::Document.new(xml) }.not_to raise_error
  end
end
