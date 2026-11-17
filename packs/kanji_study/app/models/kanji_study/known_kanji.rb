module KanjiStudy
  # Marca de "ya lo sé" para un kanji (como mucho una por kanji).
  class KnownKanji < ApplicationRecord
    self.table_name = "known_kanjis"

    belongs_to :kanji, class_name: "KanjiStudy::Kanji", inverse_of: :known_mark

    validates :kanji, uniqueness: true

    attribute :marked_on, :date, default: -> { Date.current }

    # Marca un kanji como sabido; si ya lo estaba, no hace nada.
    def self.mark(kanji)
      find_or_create_by!(kanji:)
    end

    def self.unmark(kanji)
      where(kanji:).destroy_all
    end
  end
end
