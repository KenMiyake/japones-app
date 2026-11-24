class AddNewRankToSrsCards < ActiveRecord::Migration[8.1]
  def change
    # Orden en que entran las tarjetas nuevas al repaso (menor primero). Lo fija cada dominio
    # (en kanji: el orden del plan), así el motor puede elegirlas sin saber qué son.
    add_column :srs_cards, :new_rank, :integer
    add_index :srs_cards, [ :state, :new_rank ]
  end
end
