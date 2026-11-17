module KanjiStudy
  class WordKanji < ApplicationRecord
    self.table_name = "word_kanjis"

    belongs_to :word, class_name: "KanjiStudy::Word", inverse_of: :word_kanjis
    belongs_to :kanji, class_name: "KanjiStudy::Kanji", inverse_of: :word_kanjis
  end
end
