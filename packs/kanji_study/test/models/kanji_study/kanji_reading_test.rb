require "test_helper"

module KanjiStudy
  class KanjiReadingTest < ActiveSupport::TestCase
    def build(**attrs)
      KanjiReading.new({ kanji: kanjis(:hito), kind: "on", kana: "ジン" }.merge(attrs))
    end

    test "on'yomi en katakana" do
      assert build(kana: "ジン").valid?
      assert build(kana: "コー").valid?

      reading = build(kana: "じん")
      assert_not reading.valid?
      assert_includes reading.errors.full_messages, "Lectura de una lectura on va en katakana (ej.: ショク)"
    end

    test "kun'yomi en hiragana" do
      assert build(kind: "kun", kana: "ひと").valid?
      assert_not build(kind: "kun", kana: "ヒト").valid?
    end

    test "el okurigana solo va en lecturas kun y en hiragana" do
      assert build(kind: "kun", kana: "た", okurigana: "べる").valid?
      assert_not build(kind: "on", kana: "ショク", okurigana: "べる").valid?
      assert_not build(kind: "kun", kana: "た", okurigana: "ベル").valid?
    end

    test "quita puntos y espacios al normalizar (た.べる)" do
      reading = build(kind: "kun", kana: " た. ", okurigana: ".べる")

      assert_equal "た", reading.kana
      assert_equal "べる", reading.okurigana
    end

    test "el tipo solo puede ser on o kun" do
      assert_not build(kind: "nanori").valid?
    end

    test "to_s marca el okurigana" do
      assert_equal "た·べる", kanji_readings(:taberu_ta).to_s
      assert_equal "ショク", kanji_readings(:taberu_shoku).to_s
    end
  end
end
