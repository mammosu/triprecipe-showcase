FactoryBot.define do
  factory :recipe_collaborator do
    association :recipe
    role { "viewer" }
    invitation_token { SecureRandom.urlsafe_base64(24) }
    invited_at { Time.current }
  end
end
