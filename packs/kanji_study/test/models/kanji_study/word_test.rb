require "test_helper"

module KanjiStudy
  class WordTest < ActiveSupport::TestCase
    test "al crearse se enlaza con los kanji registrados que contiene, en orden" do
      word = Word.create!(text: "人間", reading: "にんげん")

      assert_equal %w[人 間], word.kanjis.map(&:character)
      assert_empty word.unregistered_kanji
    end

    test "ignora el kana y los kanji repetidos" do
      word = Word.create!(text: "食べ食べ", reading: "たべたべ")

      assert_equal %w[食], word.kanji_characters
      assert_equal 1, word.word_kanjis.count
    end

    test "informa los kanji que no están registrados" do
      assert_equal %w[事], words(:shokuji).unregistered_kanji
    end

    test "al cambiar el texto rehace los enlaces" do
      word = words(:shokuji)

      word.update!(text: "間食", reading: "かんしょく")

      assert_equal %w[間 食], word.kanjis.map(&:character)
    end

    test "cuando se crea un kanji que faltaba, la palabra se enlaza sola" do
      word = words(:shokuji)

      Kanji.create!(character: "事")

      assert_equal %w[食 事], word.reload.kanjis.map(&:character)
    end

    test "si un kanji cambia de carácter, se desenlaza de las palabras del carácter anterior" do
      kanjis(:taberu).update!(character: "飲")

      assert_empty words(:shokuji).reload.kanjis
    end

    test "la lectura va en kana y es única para la misma palabra" do
      assert_not Word.new(text: "電車", reading: "densha").valid?
      assert Word.new(text: "今日", reading: "きょう").valid?

      Word.create!(text: "今日", reading: "きょう")
      assert Word.new(text: "今日", reading: "こんにち").valid?

      duplicate = Word.new(text: "今日", reading: "きょう")
      assert_not duplicate.valid?
      assert_includes duplicate.errors.full_messages, "Lectura ya existe para esta palabra"
    end

    test "search busca en palabra, lectura y significado" do
      assert_equal [ words(:shokuji) ], Word.search("しょく").to_a
      assert_equal [ words(:shokuji) ], Word.search("COMIDA").to_a
      assert_equal [ words(:hito) ], Word.search("人").to_a
      assert_empty Word.search("%")
    end

    test "el kanji conoce sus palabras" do
      assert_equal [ words(:shokuji) ], kanjis(:taberu).words.to_a
    end
  end
end
