class CreateComponents < ActiveRecord::Migration[8.1]
  def change
    # Piezas de los kanji (亻, 宀, o un nombre propio como "techo"). Ver docs/decisions/0003.
    create_table :components do |t|
      t.string :character
      t.string :name
      t.string :meaning_es

      t.timestamps
    end

    add_index :components, :character, unique: true, where: "character IS NOT NULL"
    add_index :components, "lower(name)", unique: true, where: "name IS NOT NULL", name: "index_components_on_lower_name"
    add_check_constraint :components, "character IS NOT NULL OR name IS NOT NULL", name: "components_character_or_name"
  end
end
