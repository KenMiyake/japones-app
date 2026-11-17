require "test_helper"

module KanjiStudy
  class ComponentTest < ActiveSupport::TestCase
    test "basta con el carácter o el nombre" do
      assert Component.new(character: "木").valid?
      assert Component.new(name: "árbol chico").valid?

      empty = Component.new(meaning_es: "algo")
      assert_not empty.valid?
      assert_includes empty.errors.full_messages, "Escribe el carácter o el nombre de la pieza"
    end

    test "el carácter es uno solo y único; el nombre es único sin importar mayúsculas" do
      assert_not Component.new(character: "木木").valid?
      assert_not Component.new(character: "亻").valid?
      assert_not Component.new(name: "TECHO").valid?
    end

    test "find_by_token busca por carácter o por nombre" do
      assert_equal components(:ninben), Component.find_by_token("亻")
      assert_equal components(:yane), Component.find_by_token(" Techo ")
      assert_nil Component.find_by_token("nada")
      assert_nil Component.find_by_token("")
    end

    test "build_from_token pone un solo carácter en character y lo demás en name" do
      assert_equal "木", Component.build_from_token("木").character
      assert_equal "dos árboles", Component.build_from_token("dos árboles").name
    end

    test "token y label" do
      assert_equal "𠆢", components(:yane).token
      assert_equal "𠆢 techo", components(:yane).label
      assert_equal "algo bueno", components(:bueno).token
    end

    test "al eliminar la pieza se quita de los kanji, sin eliminarlos" do
      assert_no_difference -> { Kanji.count } do
        components(:yane).destroy
      end
      assert_equal [ components(:bueno) ], kanjis(:taberu).reload.components.to_a
    end
  end
end
