class CreateLessons < ActiveRecord::Migration[8.1]
  def change
    create_table :lessons do |t|
      t.integer :number, null: false
      t.string :title

      t.timestamps
    end

    add_index :lessons, :number, unique: true
    add_check_constraint :lessons, "number > 0", name: "lessons_number_positive"
  end
end
