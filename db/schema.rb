# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_19_105402) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.json "metadata", default: {}, null: false
    t.bigint "whodunnit"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["item_type", "item_id"], name: "index_audit_logs_on_item_type_and_item_id"
    t.index ["whodunnit"], name: "index_audit_logs_on_whodunnit"
  end

  create_table "cities", force: :cascade do |t|
    t.string "country_code", limit: 2
    t.datetime "created_at", null: false
    t.string "name_en"
    t.string "name_ja", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["country_code"], name: "index_cities_on_country_code"
    t.index ["slug"], name: "index_cities_on_slug", unique: true
  end

  create_table "city_aliases", force: :cascade do |t|
    t.integer "city_id", null: false
    t.datetime "created_at", null: false
    t.string "normalized_name", null: false
    t.string "raw_name", null: false
    t.datetime "updated_at", null: false
    t.index ["city_id", "normalized_name"], name: "index_city_aliases_on_city_id_and_normalized_name", unique: true
    t.index ["city_id"], name: "index_city_aliases_on_city_id"
    t.index ["normalized_name"], name: "index_city_aliases_on_normalized_name"
  end

  create_table "event_logs", force: :cascade do |t|
    t.integer "actor_id"
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.json "metadata"
    t.integer "recipe_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_event_logs_on_actor_id"
    t.index ["event_type"], name: "index_event_logs_on_event_type"
    t.index ["recipe_id"], name: "index_event_logs_on_recipe_id"
  end

  create_table "recipe_collaborators", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.string "invitation_token"
    t.string "invite_email"
    t.datetime "invited_at"
    t.integer "recipe_id", null: false
    t.string "role", default: "viewer", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["invitation_token"], name: "index_recipe_collaborators_on_invitation_token", unique: true, where: "invitation_token IS NOT NULL"
    t.index ["recipe_id", "invite_email"], name: "index_recipe_collaborators_on_recipe_id_and_invite_email", unique: true, where: "invite_email IS NOT NULL"
    t.index ["recipe_id", "user_id"], name: "index_recipe_collaborators_on_recipe_id_and_user_id", unique: true
    t.index ["recipe_id"], name: "index_recipe_collaborators_on_recipe_id"
    t.index ["user_id"], name: "index_recipe_collaborators_on_user_id"
  end

  create_table "recipe_days", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "day_order", null: false
    t.string "last_edited_by_email"
    t.integer "last_edited_by_id"
    t.text "notes"
    t.integer "recipe_id", null: false
    t.date "starts_on"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["last_edited_by_id"], name: "index_recipe_days_on_last_edited_by_id"
    t.index ["recipe_id", "day_order"], name: "index_recipe_days_on_recipe_id_and_day_order", unique: true
    t.index ["recipe_id"], name: "index_recipe_days_on_recipe_id"
    t.check_constraint "day_order >= 1", name: "travel_days_day_order_positive"
  end

  create_table "recipe_reports", force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", null: false
    t.integer "handled_by_user_id"
    t.string "reason", null: false
    t.integer "recipe_id", null: false
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["handled_by_user_id"], name: "index_recipe_reports_on_handled_by_user_id"
    t.index ["recipe_id", "user_id"], name: "index_recipe_reports_on_recipe_id_and_user_id", unique: true
    t.index ["recipe_id"], name: "index_recipe_reports_on_recipe_id"
    t.index ["user_id"], name: "index_recipe_reports_on_user_id"
  end

  create_table "recipe_share_access_logs", force: :cascade do |t|
    t.datetime "accessed_at", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.integer "recipe_share_token_id", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["accessed_at"], name: "index_recipe_share_access_logs_on_accessed_at"
    t.index ["recipe_share_token_id"], name: "index_recipe_share_access_logs_on_recipe_share_token_id"
  end

  create_table "recipe_share_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.integer "recipe_id", null: false
    t.datetime "revoked_at"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id"], name: "index_recipe_share_tokens_on_recipe_id"
    t.index ["token"], name: "index_recipe_share_tokens_on_token", unique: true
  end

  create_table "recipe_slugs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "recipe_id", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id"], name: "index_recipe_slugs_on_recipe_id"
    t.index ["slug"], name: "index_recipe_slugs_on_slug", unique: true
  end

  create_table "recipe_steps", force: :cascade do |t|
    t.string "category", default: "activity", null: false
    t.datetime "created_at", null: false
    t.time "ends_at"
    t.string "last_edited_by_email"
    t.integer "last_edited_by_id"
    t.text "notes"
    t.text "photos_state"
    t.integer "position", null: false
    t.integer "recipe_day_id", null: false
    t.time "starts_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["last_edited_by_id"], name: "index_recipe_steps_on_last_edited_by_id"
    t.index ["recipe_day_id"], name: "index_recipe_steps_on_recipe_day_id"
    t.check_constraint "ends_at IS NULL OR ends_at >= starts_at", name: "timeline_items_chronological"
  end

  create_table "recipe_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "recipe_id", null: false
    t.integer "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id", "tag_id"], name: "index_recipe_tags_on_recipe_id_and_tag_id", unique: true
    t.index ["recipe_id"], name: "index_recipe_tags_on_recipe_id"
    t.index ["tag_id"], name: "index_recipe_tags_on_tag_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.string "city_display"
    t.integer "city_id"
    t.datetime "created_at", null: false
    t.integer "days_count"
    t.text "description"
    t.integer "forked_from_recipe_id"
    t.string "last_edited_by_email"
    t.integer "last_edited_by_id"
    t.boolean "public", default: true, null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["city_id"], name: "index_recipes_on_city_id"
    t.index ["forked_from_recipe_id"], name: "index_recipes_on_forked_from_recipe_id"
    t.index ["last_edited_by_id"], name: "index_recipes_on_last_edited_by_id"
    t.index ["slug"], name: "index_recipes_on_slug", unique: true
    t.index ["user_id"], name: "index_recipes_on_user_id"
    t.check_constraint "days_count IS NULL OR (days_count >= 1 AND days_count <= 60)", name: "travel_plans_days_count_range"
  end

  create_table "saved_recipes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "recipe_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["recipe_id"], name: "index_saved_recipes_on_recipe_id"
    t.index ["user_id", "recipe_id"], name: "index_saved_recipes_on_user_id_and_recipe_id", unique: true
    t.index ["user_id"], name: "index_saved_recipes_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "label_ja"
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_tags_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "display_name", default: "", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index "lower(username)", name: "index_users_on_lower_username", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "actor_email"
    t.string "cover_image_action"
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.text "object", limit: 1073741823
    t.text "object_changes", limit: 1073741823
    t.string "whodunnit"
    t.index ["actor_email"], name: "index_versions_on_actor_email"
    t.index ["cover_image_action"], name: "index_versions_on_cover_image_action"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "city_aliases", "cities"
  add_foreign_key "event_logs", "recipes"
  add_foreign_key "event_logs", "users", column: "actor_id"
  add_foreign_key "recipe_collaborators", "recipes"
  add_foreign_key "recipe_collaborators", "users"
  add_foreign_key "recipe_days", "recipes"
  add_foreign_key "recipe_days", "users", column: "last_edited_by_id"
  add_foreign_key "recipe_reports", "recipes"
  add_foreign_key "recipe_reports", "users"
  add_foreign_key "recipe_reports", "users", column: "handled_by_user_id"
  add_foreign_key "recipe_share_access_logs", "recipe_share_tokens"
  add_foreign_key "recipe_share_tokens", "recipes"
  add_foreign_key "recipe_slugs", "recipes"
  add_foreign_key "recipe_steps", "recipe_days"
  add_foreign_key "recipe_steps", "users", column: "last_edited_by_id"
  add_foreign_key "recipe_tags", "recipes"
  add_foreign_key "recipe_tags", "tags"
  add_foreign_key "recipes", "cities"
  add_foreign_key "recipes", "recipes", column: "forked_from_recipe_id", on_delete: :nullify
  add_foreign_key "recipes", "users"
  add_foreign_key "recipes", "users", column: "last_edited_by_id"
  add_foreign_key "saved_recipes", "recipes"
  add_foreign_key "saved_recipes", "users"
end
