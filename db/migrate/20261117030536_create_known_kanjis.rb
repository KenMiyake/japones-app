class CreateKnownKanjis < ActiveRecord::Migration[8.1]
  def change
    # Kanji que ya se saben. Es progreso, no contenido: por eso va en su propia tabla
    # (ver docs/decisions/0003). En la v2 servirá de estado inicial para el repaso.
    create_table :known_kanjis do |t|
      t.references :kanji, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.date :marked_on, null: false, default: -> { "CURRENT_DATE" }

      t.timestamps
    end
  end
end
