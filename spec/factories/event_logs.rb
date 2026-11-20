FactoryBot.define do
  factory :event_log do
    event_type { "recipe_view" }
    association :recipe
    association :actor, factory: :user
    metadata { {} }
  end
end
