require "rails_helper"

RSpec.describe "Auditable changes", type: :model, use_transactional_fixtures: false do
  include ActiveJob::TestHelper
  let(:user) { User.create!(email: "audit-user@example.com", password: "password123", password_confirmation: "password123") }

  before do
    Current.user = user
  end

  after do
    Current.user = nil
  end

  it "records metadata on create" do
    perform_enqueued_jobs do
      recipe = Recipe.create!(title: "AuditCreate", user: user, slug: "audit-create")
      log = AuditLog.where(item_type: "Recipe", item_id: recipe.id).order(created_at: :desc).first
      expect(log.metadata["title"]["new"]).to eq("AuditCreate")
    end
  end

  it "records attachment change on update without duplicating logs" do
    recipe = Recipe.create!(title: "AuditAttachment", user: user, slug: "audit-attachment")

    perform_enqueued_jobs do
      recipe.update!(cover_image: Rack::Test::UploadedFile.new("spec/fixtures/files/cover.png", "image/png"))
    end

    logs = AuditLog.where(item_type: "Recipe", item_id: recipe.id, action: "update").order(:created_at)
    expect(logs.size).to eq(1)
    expect(logs.first.metadata["cover_image"]["new"]).to eq("cover.png")
  end

  it "records destroy with attachments" do
    recipe = Recipe.create!(title: "AuditDestroy", user: user, slug: "audit-destroy")
    recipe.update!(cover_image: Rack::Test::UploadedFile.new("spec/fixtures/files/cover.png", "image/png"))

    perform_enqueued_jobs do
      recipe.destroy!
    end

    log = AuditLog.where(item_type: "Recipe", item_id: recipe.id, action: "destroy").order(created_at: :desc).first
    expect(log).to be_present
    expect(log.metadata["cover_image"]["old"]).to eq("removed")
  end
end
