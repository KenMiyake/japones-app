class CreateKanjis < ActiveRecord::Migration[8.1]
  def change
    create_table :kanjis do |t|
      t.string :character, null: false
      # Semana y lección son opcionales: hay kanji de referencia (para los pares) y
      # kanji cuya lección todavía no se conoce. Ver docs/decisions/0003.
      # Si se borra la semana o la lección, el kanji queda sin ella (no se bloquea el borrado:
      # core no sabe que existen kanji).
      t.references :plan_week, foreign_key: { on_delete: :nullify }
      t.integer :position
      t.references :lesson, foreign_key: { on_delete: :nullify }
      t.string :meaning_es
      t.text :mnemonic
      t.text :notes

      t.timestamps
    end

    add_index :kanjis, :character, unique: true
    add_index :kanjis, [ :plan_week_id, :position ]
  end
end
