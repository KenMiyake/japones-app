module KanjiStudy
  module WordsHelper
    # La palabra con un kanji resaltado en bermellón: 電車 con 車 → 電<span>車</span>
    def word_with_highlight(word, character)
      safe_join(word.text.each_char.map { |c| c == character ? tag.span(c, class: "text-shu") : c })
    end
  end
end
