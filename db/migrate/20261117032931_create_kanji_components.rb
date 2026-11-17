class CreateKanjiComponents < ActiveRecord::Migration[8.1]
  def change
    create_table :kanji_components do |t|
      t.references :kanji, null: false, foreign_key: { on_delete: :cascade }
      t.references :component, null: false, foreign_key: { on_delete: :cascade }
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :kanji_components, [ :kanji_id, :component_id ], unique: true
  end
end
