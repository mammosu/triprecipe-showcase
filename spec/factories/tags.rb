FactoryBot.define do
  factory :tag do
    sequence(:key) { |n| "tag-#{n}" }
    sequence(:label_ja) { |n| "タグ#{n}" }
    sequence(:position) { |n| n }
    active { true }
  end
end
