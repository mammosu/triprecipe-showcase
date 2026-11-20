FactoryBot.define do
  factory :recipe_report do
    association :recipe
    association :user
    reason { "spam" }
    status { "open" }
    comment { "不適切な内容です。" }
  end
end
