# frozen_string_literal: true

# Idempotent city + city_alias seeds extracted from db/seeds.rb
# Can be loaded from db/seeds.rb via `require_relative 'seeds/cities'`.

require 'yaml'

templates_path = File.join(__dir__, 'city_templates.yml')
city_templates = YAML.load_file(templates_path) || []

city_templates.each do |attrs|
  aliases = attrs.delete(:aliases) || []
  # YAML loads keys as strings
  aliases = attrs.delete('aliases') || aliases
  city = City.find_or_create_by!(slug: attrs['slug']) do |c|
    c.name_ja = attrs['name_ja']
    c.name_en = attrs['name_en']
    c.country_code = attrs['country_code']
  end

  # Replace existing aliases for this city so seeds remain idempotent
  city.city_aliases.destroy_all

  seen = {}
  aliases.each do |value|
    normalized = City.normalize(value)
    next if normalized.blank? || seen[normalized]

    seen[normalized] = true
    city.city_aliases.create!(raw_name: value, normalized_name: normalized)
  rescue ActiveRecord::RecordNotUnique
    next
  end
end
