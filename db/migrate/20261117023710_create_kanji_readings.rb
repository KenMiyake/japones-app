class CreateKanjiReadings < ActiveRecord::Migration[8.1]
  def change
    create_table :kanji_readings do |t|
      t.references :kanji, null: false, foreign_key: { on_delete: :cascade }
      t.string :kind, null: false # "on" | "kun"
      t.string :kana, null: false
      t.string :okurigana
      t.integer :position, null: false, default: 0
      t.boolean :taught, null: false, default: false # ¿la enseña Minna?

      t.timestamps
    end

    # Para buscar kanji que comparten lectura (コウ → 高, 校, 後…).
    add_index :kanji_readings, :kana
    add_check_constraint :kanji_readings, "kind IN ('on', 'kun')", name: "kanji_readings_kind"
  end
end
