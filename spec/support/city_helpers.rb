module CityHelpers
  def create_city_with_aliases(name:, aliases:, **attrs)
    create(:city, :with_aliases, name_ja: name, alias_values: aliases, **attrs)
  end
end

RSpec.configure do |config|
  config.include CityHelpers
end
