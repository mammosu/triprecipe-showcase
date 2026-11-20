FactoryBot.define do
  factory :city do
    sequence(:name_ja) { |n| "都市#{n}" }
    sequence(:name_en) { |n| "City#{n}" }
    country_code { "JP" }
    sequence(:slug) { |n| "city-#{n}" }

    trait :with_aliases do
      transient do
        alias_values { [ name_ja, name_en, slug.upcase ] }
      end

      after(:build) do |city, evaluator|
        next if city.city_aliases.any?

        seen = {}
        Array(evaluator.alias_values).each do |value|
          normalized = City.normalize(value)
          next if normalized.blank? || seen[normalized]

          seen[normalized] = true
          city.city_aliases.build(raw_name: value, normalized_name: normalized)
        end
      end
    end
  end
end
