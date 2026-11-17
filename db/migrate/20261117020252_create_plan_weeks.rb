class CreatePlanWeeks < ActiveRecord::Migration[8.1]
  def change
    create_table :plan_weeks do |t|
      t.string :code, null: false
      t.integer :position, null: false
      t.date :starts_on, null: false
      # Números de lección de Minna (no FKs): el rango es una referencia, no una relación.
      t.integer :first_lesson, null: false
      t.integer :last_lesson, null: false
      t.boolean :provisional, null: false, default: false

      t.timestamps
    end

    add_index :plan_weeks, :code, unique: true
    add_index :plan_weeks, :position, unique: true
    add_check_constraint :plan_weeks, "last_lesson >= first_lesson", name: "plan_weeks_lesson_range"
  end
end
