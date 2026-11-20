require "rails_helper"

RSpec.describe "RecipeStep photos", type: :request do
  include ActionDispatch::TestProcess::FixtureFile
  include ActiveJob::TestHelper
  let!(:user) { User.create!(email: "photos-user@example.com", password: "password123", password_confirmation: "password123") }
  let!(:recipe) { Recipe.create!(title: "リスボン週末", city_display: "リスボン", description: "", public: true, user: user) }
  let!(:recipe_day) { recipe.recipe_days.create!(title: "1日目", day_order: 1) }

  let(:photo) { fixture_file_upload("cover.png", "image/png") }

  before { sign_in user }

  describe "POST create with photos" do
    it "attaches photos, logs audit, and records paper trail" do
      expect do
        perform_enqueued_jobs do
          post recipe_day_steps_path(recipe, recipe_day), params: {
            recipe_step: {
              title: "朝食",
              starts_at: "08:00",
              category: "food",
              photos: [ photo, photo ]
            }
          }
        end
      end.to change(RecipeStep, :count).by(1)

      step = recipe_day.recipe_steps.last

      # audit log
      log = AuditLog.where(action: "recipe_step.photos_added").order(:created_at).last
      expect(log).to be_present
      expect(log.metadata["added"].size).to eq(2)
      log.metadata["added"].each do |entry|
        expect(entry).to include(
          "attachment_id",
          "blob_id",
          "filename",
          "content_type",
          "byte_size"
        )
      end

      # paper trail
      expect(step.versions.last.event).to eq("photos_attach")
      expect(step.versions.last.whodunnit).to eq(user.id.to_s)
      expect(step.versions.last.actor_email).to eq(user.email)
      changes = PaperTrail.serializer.load(step.versions.last.object_changes)
      expect(changes.keys).to include("photos_state")
      expect(step.versions.where(event: "photos_attach").count).to eq(1)
      expect(step.photos.count).to eq(2)
    end
  end

  describe "PATCH update with photos" do
    it "adds photos and records a single version" do
      step = recipe_day.recipe_steps.create!(title: "昼食", starts_at: Time.zone.parse("12:00"), category: "food")

      expect do
        perform_enqueued_jobs do
          patch recipe_day_step_path(recipe, recipe_day, step), params: {
            recipe_step: {
              title: step.title,
              starts_at: step.starts_at,
              category: step.category,
              photos: [ photo ]
            }
          }
        end
      end.to change { step.reload.versions.count }.by(1)

      expect(step.versions.last.event).to eq("photos_attach")
      changes = PaperTrail.serializer.load(step.versions.last.object_changes)
      expect(changes.keys).to include("photos_state")
    end
  end

  describe "DELETE photo" do
    it "removes the attachment, logs audit, and versions" do
      step = recipe_day.recipe_steps.create!(title: "昼食", starts_at: Time.zone.parse("12:00"), category: "food")
      step.photos.attach(photo)
      step.sync_photos_state!(paper_trail_event: "photos_attach")

      attachment = step.photos.first

      perform_enqueued_jobs do
        expect do
          delete recipe_day_step_photo_path(recipe, recipe_day, step, attachment)
        end.to change { step.reload.photos.count }.from(1).to(0)
           .and change { step.reload.versions.count }.by(1)
      end

      log = AuditLog.order(:created_at).last
      expect(log.action).to eq("recipe_step.photo_removed")
      expect(log.metadata["removed"]["attachment_id"]).to eq(attachment.id)
      expect(log.metadata["removed"]).to include(
        "attachment_id",
        "blob_id",
        "filename",
        "content_type",
        "byte_size"
      )

      step.reload
      expect(step.versions.last.event).to eq("photos_purge")
      expect(step.versions.last.whodunnit).to eq(user.id.to_s)
      expect(step.versions.last.actor_email).to eq(user.email)
      changes = PaperTrail.serializer.load(step.versions.last.object_changes)
      expect(changes.keys).to include("photos_state")
    end
  end
end
