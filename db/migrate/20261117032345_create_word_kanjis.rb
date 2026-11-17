class CreateWordKanjis < ActiveRecord::Migration[8.1]
  def change
    create_table :word_kanjis do |t|
      t.references :word, null: false, foreign_key: { on_delete: :cascade }
      t.references :kanji, null: false, foreign_key: { on_delete: :cascade }
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :word_kanjis, [ :word_id, :kanji_id ], unique: true
  end
end
