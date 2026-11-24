class CreateSrsReviews < ActiveRecord::Migration[8.1]
  def change
    # Un repaso: la respuesta y el estado de la tarjeta ANTES de responder (espejo de
    # FsrsRuby::ReviewLog). Con esto se puede deshacer un repaso o recalcular el historial
    # si cambia el algoritmo.
    create_table :srs_reviews do |t|
      t.references :card, null: false, foreign_key: { to_table: :srs_cards, on_delete: :cascade }
      t.string :rating, null: false # again | hard | good | easy
      t.datetime :reviewed_at, null: false

      t.string :state, null: false
      t.datetime :due_at, null: false
      t.float :stability, null: false
      t.float :difficulty, null: false
      t.integer :elapsed_days, null: false
      t.integer :last_elapsed_days, null: false
      t.integer :scheduled_days, null: false
      t.integer :learning_steps, null: false

      t.timestamps
    end

    add_index :srs_reviews, [ :card_id, :reviewed_at ]
    add_index :srs_reviews, :reviewed_at
    add_check_constraint :srs_reviews, "rating IN ('again', 'hard', 'good', 'easy')", name: "srs_reviews_rating"
  end
end
