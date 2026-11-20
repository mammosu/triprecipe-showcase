require "rails_helper"

RSpec.describe "AuditLogs", type: :request do
  let(:owner) { User.create!(email: "audit-owner@example.com", password: "password123", password_confirmation: "password123") }
  let(:admin_collaborator) { User.create!(email: "audit-admin@example.com", password: "password123", password_confirmation: "password123") }
  let(:recipe) { Recipe.create!(title: "Audit Plan", user: owner, slug: "audit-plan") }

  before do
    RecipeCollaborator.create!(recipe: recipe, user: admin_collaborator, role: :admin)
  end

  it "allows admin collaborator to view audit logs" do
    sign_in admin_collaborator
    get recipe_audit_logs_path(recipe)
    expect(response).to have_http_status(:success)
  end

  it "denies viewer collaborator" do
    viewer = User.create!(email: "audit-viewer@example.com", password: "password123", password_confirmation: "password123")
    RecipeCollaborator.create!(recipe: recipe, user: viewer, role: :viewer)

    sign_in viewer
    get recipe_audit_logs_path(recipe)
    expect(response).to redirect_to(recipes_path).or have_http_status(:forbidden)
  end

  it "renders nested metadata values for photo add/remove" do
    day = recipe.recipe_days.create!(title: "1日目", day_order: 1)
    step = day.recipe_steps.create!(title: "朝食", starts_at: Time.zone.parse("08:00"), category: "food")

    AuditLog.create!(
      item_type: "RecipeStep",
      item_id: step.id,
      action: "recipe_step.photos_added",
      whodunnit: owner.id,
      metadata: {
        step_id: step.id,
        recipe_id: recipe.id,
        day_id: day.id,
        added: [
          {
            attachment_id: 101,
            blob_id: 201,
            filename: "added-file.jpg",
            content_type: "image/jpeg",
            byte_size: 1234
          }
        ]
      },
      created_at: Time.current
    )

    AuditLog.create!(
      item_type: "RecipeStep",
      item_id: step.id,
      action: "recipe_step.photo_removed",
      whodunnit: owner.id,
      metadata: {
        step_id: step.id,
        recipe_id: recipe.id,
        day_id: day.id,
        removed: {
          attachment_id: 102,
          blob_id: 202,
          filename: "removed-file.jpg",
          content_type: "image/jpeg",
          byte_size: 5678
        }
      },
      created_at: Time.current
    )

    sign_in owner
    get recipe_audit_logs_path(recipe)
    expect(response).to have_http_status(:success)
    expect(response.body).to include("added-file.jpg")
    expect(response.body).to include("removed-file.jpg")
    expect(response.body).to include("attachment_id")
    expect(response.body).to include("content_type")
  end
end
