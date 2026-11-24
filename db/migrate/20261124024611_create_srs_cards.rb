class CreateSrsCards < ActiveRecord::Migration[8.1]
  def change
    # Tarjeta de repaso: algo repasable (un kanji, un grupo para distinguir…) + un tipo de
    # tarjeta (read, write, distinguish), con su estado FSRS. Ver docs/decisions/0004.
    create_table :srs_cards do |t|
      t.references :reviewable, polymorphic: true, null: false
      t.string :card_type, null: false

      # Estado FSRS (espejo de FsrsRuby::Card)
      t.string :state, null: false, default: "new" # new | learning | review | relearning
      t.datetime :due_at, null: false
      t.float :stability, null: false, default: 0.0
      t.float :difficulty, null: false, default: 0.0
      t.integer :elapsed_days, null: false, default: 0
      t.integer :scheduled_days, null: false, default: 0
      t.integer :learning_steps, null: false, default: 0
      t.integer :reps, null: false, default: 0
      t.integer :lapses, null: false, default: 0
      t.datetime :last_reviewed_at

      t.timestamps
    end

    add_index :srs_cards, [ :reviewable_type, :reviewable_id, :card_type ], unique: true,
                                                                          name: "index_srs_cards_on_reviewable_and_type"
    add_index :srs_cards, :due_at
    add_check_constraint :srs_cards, "state IN ('new', 'learning', 'review', 'relearning')", name: "srs_cards_state"
  end
end
