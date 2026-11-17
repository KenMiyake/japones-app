module KanjiStudy
  # Palabra de ejemplo. Al guardarse se enlaza sola con los kanji registrados que contiene
  # (図書館 → 図, 書, 館). Los que no están registrados quedan en `unregistered_kanji`
  # para avisarlo; cuando se creen, Kanji vuelve a enlazar las palabras que los contienen.
  class Word < ApplicationRecord
    self.table_name = "words"

    KANA = /\A[\p{Hiragana}\p{Katakana}ー・\s]+\z/

    belongs_to :lesson, optional: true
    has_many :word_kanjis, -> { order(:position) },
             class_name: "KanjiStudy::WordKanji", inverse_of: :word, dependent: :destroy
    has_many :kanjis, through: :word_kanjis

    normalizes :text, :reading, with: ->(value) { value.strip }
    normalizes :meaning_es, with: ->(value) { value.strip.presence }

    validates :text, presence: true
    validates :reading, presence: true, uniqueness: { scope: :text }
    validates :reading, format: { with: KANA, message: :kana_only }, allow_blank: true

    after_save :link_kanjis!, if: :saved_change_to_text?

    scope :ordered, -> { order(:reading, :text) }
    scope :containing, ->(character) { where("text LIKE ?", "%#{sanitize_sql_like(character)}%") }
    scope :search, ->(query) {
      pattern = "%#{sanitize_sql_like(query.strip)}%"
      where("text ILIKE :p OR reading ILIKE :p OR meaning_es ILIKE :p", p: pattern)
    }

    # Kanji del texto, sin repetir y en orden: "日曜日" → ["日", "曜"]
    def kanji_characters
      text.to_s.scan(/\p{Han}/).uniq
    end

    def unregistered_kanji
      kanji_characters - kanjis.map(&:character)
    end

    # Rehace los enlaces a partir del texto.
    def link_kanjis!
      found = Kanji.where(character: kanji_characters).index_by(&:character)
      word_kanjis.delete_all
      kanji_characters.filter_map { |c| found[c] }.each_with_index do |kanji, position|
        word_kanjis.create!(kanji:, position:)
      end
      association(:kanjis).reset
    end
  end
end
