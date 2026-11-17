require "test_helper"

module KanjiStudy
  class KanjiTest < ActiveSupport::TestCase
    test "es válido con solo el carácter" do
      assert Kanji.new(character: "水").valid?
    end

    test "el carácter es un solo kanji, sin espacios y único" do
      assert_not Kanji.new(character: "日本").valid?
      assert_not Kanji.new(character: "あ").valid?
      assert_not Kanji.new(character: "A").valid?

      kanji = Kanji.new(character: " 水 ")
      assert kanji.valid?
      assert_equal "水", kanji.character

      duplicate = Kanji.new(character: kanjis(:taberu).character)
      assert_not duplicate.valid?
      assert_includes duplicate.errors[:character], "ya está en uso"
    end

    test "el mensaje de error está en español" do
      kanji = Kanji.new(character: "あ")
      kanji.valid?

      assert_includes kanji.errors.full_messages, "Kanji debe ser un solo kanji"
    end

    test "los textos vacíos se guardan como nil" do
      kanji = Kanji.new(character: "水", meaning_es: "  ", mnemonic: "")

      assert_nil kanji.meaning_es
      assert_nil kanji.mnemonic
    end

    test "separa las lecturas on y kun, en orden" do
      kanji = kanjis(:taberu)

      assert_equal %w[ショク], kanji.on_readings.map(&:kana)
      assert_equal %w[た], kanji.kun_readings.map(&:kana)
    end

    test "avisa si la lección queda fuera del rango de la semana" do
      assert kanjis(:aida).lesson_outside_plan_week?
      assert_not kanjis(:taberu).lesson_outside_plan_week?
      assert_not kanjis(:hito).lesson_outside_plan_week?
    end

    test "missing_fields lista lo que falta completar" do
      assert_empty kanjis(:taberu).missing_fields
      assert kanjis(:taberu).complete?
      assert_equal %i[readings mnemonic lesson], kanjis(:hito).missing_fields
      assert_equal %i[meaning_es readings mnemonic], kanjis(:aida).missing_fields
    end

    test "crea lecturas anidadas, ignora filas vacías y las numera en orden" do
      kanji = Kanji.create!(
        character: "水",
        readings_attributes: {
          "0" => { kind: "on", kana: "スイ" },
          "1" => { kind: "kun", kana: "", okurigana: "" },
          "2" => { kind: "kun", kana: "みず" }
        }
      )

      assert_equal [ [ "スイ", 0 ], [ "みず", 1 ] ], kanji.readings.reload.map { |r| [ r.kana, r.position ] }
    end

    test "elimina lecturas marcadas con _destroy" do
      kanji = kanjis(:taberu)
      reading = kanji_readings(:taberu_ta)

      kanji.update!(readings_attributes: { "0" => { id: reading.id, _destroy: "1" } })

      assert_equal %w[ショク], kanji.readings.reload.map(&:kana)
    end

    test "al eliminar el kanji se eliminan sus lecturas" do
      assert_difference -> { KanjiReading.count }, -2 do
        kanjis(:taberu).destroy
      end
    end

    test "in_plan_order ordena por semana y deja al final los sin semana" do
      assert_equal %w[食 間 人], Kanji.in_plan_order.map(&:character)
    end

    test "to_param es el carácter, aunque se esté editando" do
      kanji = kanjis(:taberu)
      kanji.character = "飲"

      assert_equal "食", kanji.to_param
    end
  end
end
