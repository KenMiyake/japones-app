module KanjiStudy
  class KanjiComponent < ApplicationRecord
    self.table_name = "kanji_components"

    belongs_to :kanji, class_name: "KanjiStudy::Kanji", inverse_of: :kanji_components
    belongs_to :component, class_name: "KanjiStudy::Component", inverse_of: :kanji_components
  end
end
