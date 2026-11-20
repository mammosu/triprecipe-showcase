FactoryBot.define do
  factory :recipe do
    association :user
    sequence(:title) { |n| "Plan #{n}" }
    description { "Test description" }
    days_count { 3 }
    public { true }
    city_display { nil }

    trait :with_city do
      association :city
    end
  end
end
