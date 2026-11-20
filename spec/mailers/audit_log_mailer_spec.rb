require "rails_helper"

RSpec.describe AuditLogMailer, type: :mailer do
  it "sends daily summary" do
    user = User.create!(email: "audit-mail@example.com", password: "password123", password_confirmation: "password123")
    recipe = Recipe.create!(title: "Mail Plan", user: user, slug: "mail-plan")
    log = AuditLog.create!(item_type: "Recipe", item_id: recipe.id, action: "update", whodunnit: user.id, metadata: {}, created_at: Time.current)

    mail = described_class.daily_summary(user, recipe, [ log ])

    expect(mail.to).to include(user.email)
    expect(mail.subject).to include("変更まとめ")
    expect(mail.body.encoded).to include("Mail Plan")
  end
end
