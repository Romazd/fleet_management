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

ActiveRecord::Schema[7.1].define(version: 2025_09_17_140721) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "vehicles", force: :cascade do |t|
    t.string "vin", null: false
    t.string "plate", null: false
    t.string "brand", null: false
    t.string "model", null: false
    t.integer "year", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((plate)::text)", name: "index_vehicles_on_lower_plate", unique: true
    t.index "lower((vin)::text)", name: "index_vehicles_on_lower_vin", unique: true
    t.index ["status"], name: "index_vehicles_on_status"
    t.index ["year"], name: "index_vehicles_on_year"
  end

end
