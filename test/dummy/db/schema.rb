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

ActiveRecord::Schema[8.1].define(version: 101) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "name", null: false
    t.integer "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.string "content_type"
    t.datetime "created_at", precision: nil, null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "logs", force: :cascade do |t|
    t.integer "associated_id"
    t.string "associated_to_s"
    t.string "associated_type"
    t.integer "changes_to_id"
    t.string "changes_to_type"
    t.datetime "created_at", null: false
    t.text "details"
    t.text "message"
    t.string "status"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "user_type"
    t.index ["associated_to_s"], name: "index_logs_on_associated_to_s"
    t.index ["associated_type", "associated_id"], name: "index_logs_on_associated_type_and_associated_id"
    t.index ["changes_to_type", "changes_to_id"], name: "index_logs_on_changes_to_type_and_changes_to_id"
    t.index ["details"], name: "index_logs_on_details"
    t.index ["id"], name: "index_logs_on_id", order: :desc
    t.index ["message"], name: "index_logs_on_message"
    t.index ["status"], name: "index_logs_on_status"
    t.index ["updated_at"], name: "index_logs_on_updated_at"
    t.index ["user_id"], name: "index_logs_on_user_id"
  end

  create_table "tracks", force: :cascade do |t|
    t.string "action"
    t.datetime "created_at", null: false
    t.text "details"
    t.integer "owner_id"
    t.string "owner_type"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "user_type"
    t.index ["owner_id"], name: "index_tracks_on_owner_id"
    t.index ["user_id"], name: "index_tracks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at", precision: nil
    t.datetime "confirmed_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "last_sign_in_at", precision: nil
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.integer "roles_mask"
    t.integer "sign_in_count", default: 0, null: false
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
