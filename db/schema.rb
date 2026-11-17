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

ActiveRecord::Schema[8.1].define(version: 2026_11_17_032345) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "confusable_groups", force: :cascade do |t|
    t.bigint "plan_week_id"
    t.string "practice_mode", default: "pending", null: false
    t.text "hint"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_week_id"], name: "index_confusable_groups_on_plan_week_id"
    t.check_constraint "practice_mode::text = ANY (ARRAY['card'::character varying, 'paper'::character varying, 'pending'::character varying]::text[])", name: "confusable_groups_practice_mode"
  end

  create_table "confusable_members", force: :cascade do |t|
    t.bigint "confusable_group_id", null: false
    t.bigint "kanji_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confusable_group_id", "kanji_id"], name: "index_confusable_members_on_confusable_group_id_and_kanji_id", unique: true
    t.index ["confusable_group_id"], name: "index_confusable_members_on_confusable_group_id"
    t.index ["kanji_id"], name: "index_confusable_members_on_kanji_id"
  end

  create_table "kanji_readings", force: :cascade do |t|
    t.bigint "kanji_id", null: false
    t.string "kind", null: false
    t.string "kana", null: false
    t.string "okurigana"
    t.integer "position", default: 0, null: false
    t.boolean "taught", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kana"], name: "index_kanji_readings_on_kana"
    t.index ["kanji_id"], name: "index_kanji_readings_on_kanji_id"
    t.check_constraint "kind::text = ANY (ARRAY['on'::character varying, 'kun'::character varying]::text[])", name: "kanji_readings_kind"
  end

  create_table "kanjis", force: :cascade do |t|
    t.string "character", null: false
    t.bigint "plan_week_id"
    t.integer "position"
    t.bigint "lesson_id"
    t.string "meaning_es"
    t.text "mnemonic"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character"], name: "index_kanjis_on_character", unique: true
    t.index ["lesson_id"], name: "index_kanjis_on_lesson_id"
    t.index ["plan_week_id", "position"], name: "index_kanjis_on_plan_week_id_and_position"
    t.index ["plan_week_id"], name: "index_kanjis_on_plan_week_id"
  end

  create_table "known_kanjis", force: :cascade do |t|
    t.bigint "kanji_id", null: false
    t.date "marked_on", default: -> { "CURRENT_DATE" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kanji_id"], name: "index_known_kanjis_on_kanji_id", unique: true
  end

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

  create_table "word_kanjis", force: :cascade do |t|
    t.bigint "word_id", null: false
    t.bigint "kanji_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kanji_id"], name: "index_word_kanjis_on_kanji_id"
    t.index ["word_id", "kanji_id"], name: "index_word_kanjis_on_word_id_and_kanji_id", unique: true
    t.index ["word_id"], name: "index_word_kanjis_on_word_id"
  end

  create_table "words", force: :cascade do |t|
    t.string "text", null: false
    t.string "reading", null: false
    t.string "meaning_es"
    t.bigint "lesson_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lesson_id"], name: "index_words_on_lesson_id"
    t.index ["text", "reading"], name: "index_words_on_text_and_reading", unique: true
  end

  add_foreign_key "confusable_groups", "plan_weeks", on_delete: :nullify
  add_foreign_key "confusable_members", "confusable_groups", on_delete: :cascade
  add_foreign_key "confusable_members", "kanjis", on_delete: :cascade
  add_foreign_key "kanji_readings", "kanjis", on_delete: :cascade
  add_foreign_key "kanjis", "lessons", on_delete: :nullify
  add_foreign_key "kanjis", "plan_weeks", on_delete: :nullify
  add_foreign_key "known_kanjis", "kanjis", on_delete: :cascade
  add_foreign_key "word_kanjis", "kanjis", on_delete: :cascade
  add_foreign_key "word_kanjis", "words", on_delete: :cascade
  add_foreign_key "words", "lessons", on_delete: :nullify
end
