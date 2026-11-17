require "test_helper"

module KanjiStudy
  # Piezas de un kanji escritas como texto (component_tokens), como llegan del formulario.
  class KanjiComponentsTest < ActiveSupport::TestCase
    test "component_tokens devuelve las piezas en orden" do
      assert_equal [ "𠆢", "algo bueno" ], kanjis(:taberu).component_tokens
    end

    test "reutiliza piezas existentes y crea las nuevas, informándolas" do
      kanji = kanjis(:hito)

      assert_difference -> { Component.count }, 2 do
        kanji.update!(component_tokens: [ "亻", "木", "dos brazos", "" ])
      end

      assert_equal [ "亻", "木", "dos brazos" ], kanji.reload.component_tokens
      assert_equal [ "木", "dos brazos" ], kanji.created_components.map(&:token)
      assert_equal "木", Component.find_by_token("木").character
      assert_equal "dos brazos", Component.find_by_token("dos brazos").name
    end

    test "encuentra piezas por nombre sin importar mayúsculas" do
      kanji = kanjis(:hito)

      assert_no_difference -> { Component.count } do
        kanji.update!(component_tokens: [ "TECHO" ])
      end
      assert_equal [ components(:yane) ], kanji.reload.components.to_a
    end

    test "reordena, quita piezas y no duplica" do
      kanji = kanjis(:taberu)

      kanji.update!(component_tokens: [ "algo bueno", "algo bueno" ])

      assert_equal [ "algo bueno" ], kanji.reload.component_tokens
      assert_equal [ 0 ], kanji.kanji_components.map(&:position)
    end

    test "una lista vacía quita todas las piezas" do
      kanjis(:taberu).update!(component_tokens: [ "" ])

      assert_empty kanjis(:taberu).reload.components
    end

    test "sin component_tokens, guardar no toca las piezas" do
      kanjis(:taberu).update!(meaning_es: "comer")

      assert_equal 2, kanjis(:taberu).reload.components.count
    end
  end
end
