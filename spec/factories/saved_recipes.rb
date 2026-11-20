FactoryBot.define do
  factory :saved_recipe do
    association :user
    association :recipe
  end
end
