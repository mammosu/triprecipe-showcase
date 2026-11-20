class RecipeSlugService
  require "securerandom"

  def self.generate_unique_slug_for(recipe)
    location_fragment = recipe.slug_location_fragment.presence || recipe.city_display.presence
    base_slug = [ recipe.title, location_fragment ].compact.join("-").parameterize
    return build_random_slug_for(recipe) if base_slug.blank?

    candidate = base_slug
    suffix = 2

    while recipe.class.where.not(id: recipe.id).exists?(slug: candidate)
      candidate = "#{base_slug}-#{suffix}"
      suffix += 1
    end

    candidate
  end

  def self.build_random_slug_for(recipe)
    loop do
      candidate = "rc#{SecureRandom.alphanumeric(6).downcase}"
      break candidate unless recipe.class.where.not(id: recipe.id).exists?(slug: candidate)
    end
  end

  def self.generate_unique_fork_slug_for(source_recipe)
    base = source_recipe.slug.presence || [ source_recipe.title, source_recipe.slug_location_fragment ].compact.join("-").parameterize
    base = "recipe" if base.blank?

    base_slug = "#{base}-copy"
    candidate = base_slug
    suffix = 2
    attempts = 0

    while Recipe.exists?(slug: candidate)
      candidate = "#{base_slug}-#{suffix}"
      suffix += 1
      attempts += 1
      break if attempts >= 100
    end

    return candidate unless Recipe.exists?(slug: candidate)

    build_random_slug_for(source_recipe)
  end
end
