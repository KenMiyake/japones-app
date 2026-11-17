class CreateWords < ActiveRecord::Migration[8.1]
  def change
    # Palabras de ejemplo (電車, 食べる, 図書館). Muchos a muchos con kanji (ver docs/decisions/0003).
    create_table :words do |t|
      t.string :text, null: false
      t.string :reading, null: false
      t.string :meaning_es
      t.references :lesson, foreign_key: { on_delete: :nullify }

      t.timestamps
    end

    # 今日 se lee きょう o こんにち: lo único es la combinación.
    add_index :words, [ :text, :reading ], unique: true
  end
end
