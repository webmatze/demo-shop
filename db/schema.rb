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

ActiveRecord::Schema[8.1].define(version: 2026_10_02_090000) do
  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "payout_requests", force: :cascade do |t|
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.float "probability"
    t.string "reason"
    t.string "request_country"
    t.integer "seller_id", null: false
    t.string "state", default: "open", null: false
    t.datetime "updated_at", null: false
    t.boolean "via_proxy", default: false, null: false
    t.index ["seller_id"], name: "index_payout_requests_on_seller_id"
    t.index ["state"], name: "index_payout_requests_on_state"
  end

  create_table "products", force: :cascade do |t|
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.decimal "price", precision: 8, scale: 2
    t.datetime "synced_at"
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["name"], name: "index_products_on_name", unique: true
  end

  create_table "sellers", force: :cascade do |t|
    t.integer "account_age_days", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "days_since_last_order", default: 0, null: false
    t.integer "iban_changed_hours_ago"
    t.integer "lifetime_sales", default: 0, null: false
    t.string "login_country"
    t.string "name", null: false
    t.integer "orders", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "payout_requests", "sellers"
  add_foreign_key "products", "categories"
end
