require "test_helper"

module KanjiStudy
  class WordsControllerTest < ActionDispatch::IntegrationTest
    test "el listado enlaza los kanji registrados y atenúa los que no" do
      get words_path

      assert_response :success
      assert_select "turbo-frame#words_list li##{dom_id(words(:shokuji))}" do
        assert_select "a[href=?]", kanji_path(kanjis(:taberu)), "食"
        assert_select "span[title='Kanji sin registrar']", "事"
      end
      assert_select "aside#sidebar nav a[aria-current=page]", /Palabras/
    end

    test "la búsqueda filtra la lista" do
      get words_path(q: "persona")

      assert_select "li##{dom_id(words(:hito))}"
      assert_select "li##{dom_id(words(:shokuji))}", count: 0
      assert_select "input[name=q][value=persona]"
    end

    test "sin resultados lo dice" do
      get words_path(q: "zzz")

      assert_select "turbo-frame#words_list", /No hay palabras que coincidan con «zzz»/
    end

    test "crea una palabra y avisa los kanji sin registrar" do
      assert_difference -> { Word.count }, 1 do
        post words_path, params: { word: { text: "電車", reading: "でんしゃ", meaning_es: "tren" } }
      end

      assert_redirected_to words_path
      follow_redirect!
      assert_select "[role=status]", /Palabra 電車 creada. Kanji sin registrar \(no enlazados\): 電 車/
    end

    test "creada desde la ficha de un kanji, vuelve a esa ficha" do
      get new_word_path(text: "食", return_to_kanji: "食")
      assert_select "input[name='word[text]'][value=食]"
      assert_select "input[type=hidden][name=return_to_kanji][value=食]"

      post words_path, params: { return_to_kanji: "食", word: { text: "食堂", reading: "しょくどう" } }

      assert_redirected_to kanji_path(kanjis(:taberu))
    end

    test "con datos inválidos vuelve al formulario" do
      post words_path, params: { word: { text: "電車", reading: "densha" } }

      assert_response :unprocessable_content
      assert_select "[role=alert]", /va solo en kana/
    end

    test "edita y vuelve a enlazar" do
      patch word_path(words(:hito)), params: { word: { text: "人間", reading: "にんげん" } }

      assert_redirected_to words_path
      assert_equal %w[人 間], words(:hito).reload.kanjis.map(&:character)
    end

    test "elimina la palabra" do
      assert_difference -> { Word.count }, -1 do
        delete word_path(words(:hito))
      end

      assert_redirected_to words_path
    end

    test "la ficha del kanji muestra sus palabras con el kanji resaltado" do
      get kanji_path(kanjis(:taberu))

      assert_select "section li", /しょくじ/
      assert_select "section li span.text-shu", "食"
      assert_select "a[href=?]", new_word_path(text: "食", return_to_kanji: "食")
    end
  end
end
