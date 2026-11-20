FactoryBot.define do
  factory :recipe_share_token do
    association :recipe
    token { SecureRandom.hex(10) }
    expires_at { 1.week.from_now }
  end
end
