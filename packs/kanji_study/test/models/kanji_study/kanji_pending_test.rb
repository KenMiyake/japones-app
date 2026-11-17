require "test_helper"

module KanjiStudy
  # Lo que falta completar (scopes) y las lecturas escritas como texto.
  class KanjiPendingTest < ActiveSupport::TestCase
    test "incomplete trae los kanji a los que les falta algo" do
      assert_equal %w[人 間], Kanji.incomplete.order(:character).map(&:character).sort
      assert_not_includes Kanji.incomplete, kanjis(:taberu)
    end

    test "missing filtra por campo y coincide con missing_fields" do
      Kanji::MISSING_FIELDS.each do |field|
        expected = Kanji.all.select { |kanji| kanji.missing_fields.include?(field) }
        assert_equal expected.map(&:id).sort, Kanji.missing(field).pluck(:id).sort, "campo #{field}"
      end
    end

    test "missing rechaza campos desconocidos" do
      assert_raises(ArgumentError) { Kanji.missing(:notes) }
    end

    test "las lecturas se muestran como texto" do
      assert_equal "ショク", kanjis(:taberu).on_readings_text
      assert_equal "た.べる", kanjis(:taberu).kun_readings_text
      assert_equal "", kanjis(:hito).on_readings_text
    end

    test "escribir las lecturas como texto las crea en orden, on primero" do
      kanji = kanjis(:hito)

      kanji.update!(on_readings_text: "ジン、ニン", kun_readings_text: "ひと")

      assert_equal [ %w[on ジン 0], %w[on ニン 1], %w[kun ひと 2] ],
                   kanji.readings.reload.map { |r| [ r.kind, r.kana, r.position.to_s ] }
    end

    test "acepta comas, espacios y el punto del okurigana" do
      kanji = kanjis(:aida)

      kanji.update!(on_readings_text: "カン, ケン", kun_readings_text: "あいだ  ま")

      assert_equal %w[カン ケン], kanji.reload.on_readings.map(&:kana)
      assert_equal %w[あいだ ま], kanji.kun_readings.map(&:kana)
    end

    test "conserva las lecturas existentes (y su marca de Minna), quita las que faltan y agrega las nuevas" do
      kanji = kanjis(:taberu)
      shoku = kanji_readings(:taberu_shoku)

      kanji.update!(on_readings_text: "ショク、ジキ", kun_readings_text: "く.う")

      kanji.readings.reload
      assert_equal %w[ショク ジキ], kanji.on_readings.map(&:kana)
      assert_equal shoku.id, kanji.on_readings.first.id
      assert kanji.on_readings.first.taught?, "conserva la marca de Minna"
      assert_equal [ %w[く う] ], kanji.kun_readings.map { |r| [ r.kana, r.okurigana ] }
    end

    test "si solo viene uno de los dos textos, el otro tipo no se toca" do
      kanji = kanjis(:taberu)

      kanji.update!(on_readings_text: "ショク、ジキ")

      assert_equal %w[た], kanji.reload.kun_readings.map(&:kana)
    end

    test "un texto vacío quita todas las lecturas de ese tipo" do
      kanjis(:taberu).update!(kun_readings_text: "")

      assert_empty kanjis(:taberu).reload.kun_readings
    end

    test "una lectura mal escrita no se guarda y conserva el texto para corregirlo" do
      kanji = kanjis(:hito)

      assert_not kanji.update(on_readings_text: "じん")
      assert_includes kanji.errors.full_messages.join, "katakana"
      assert_equal "じん", kanji.on_readings_text
      assert_empty kanji.readings.reload
    end
  end
end
