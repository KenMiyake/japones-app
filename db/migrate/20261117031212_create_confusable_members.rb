class CreateConfusableMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :confusable_members do |t|
      t.references :confusable_group, null: false, foreign_key: { on_delete: :cascade }
      t.references :kanji, null: false, foreign_key: { on_delete: :cascade }
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :confusable_members, [ :confusable_group_id, :kanji_id ], unique: true
  end
end
