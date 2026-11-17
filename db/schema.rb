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

ActiveRecord::Schema[8.1].define(version: 2026_11_17_020252) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "lessons", force: :cascade do |t|
    t.integer "number", null: false
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["number"], name: "index_lessons_on_number", unique: true
    t.check_constraint "number > 0", name: "lessons_number_positive"
  end

  create_table "plan_weeks", force: :cascade do |t|
    t.string "code", null: false
    t.integer "position", null: false
    t.date "starts_on", null: false
    t.integer "first_lesson", null: false
    t.integer "last_lesson", null: false
    t.boolean "provisional", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_plan_weeks_on_code", unique: true
    t.index ["position"], name: "index_plan_weeks_on_position", unique: true
    t.check_constraint "last_lesson >= first_lesson", name: "plan_weeks_lesson_range"
  end
end
