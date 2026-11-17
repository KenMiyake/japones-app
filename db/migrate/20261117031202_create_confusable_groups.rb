class CreateConfusableGroups < ActiveRecord::Migration[8.1]
  def change
    # Grupo de kanji que se confunden (人/入, o de 3: 待/持/特). Ver docs/decisions/0003.
    create_table :confusable_groups do |t|
      t.references :plan_week, foreign_key: { on_delete: :nullify }
      t.string :practice_mode, null: false, default: "pending" # card | paper | pending
      t.text :hint

      t.timestamps
    end

    add_check_constraint :confusable_groups, "practice_mode IN ('card', 'paper', 'pending')",
                         name: "confusable_groups_practice_mode"
  end
end
