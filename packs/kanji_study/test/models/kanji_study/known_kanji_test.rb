require "test_helper"

module KanjiStudy
  class KnownKanjiTest < ActiveSupport::TestCase
    test "un kanji se marca una sola vez" do
      assert_not KnownKanji.new(kanji: kanjis(:hito)).valid?
    end

    test "mark crea la marca con la fecha de hoy y es idempotente" do
      travel_to Date.new(2026, 11, 20) do
        assert_difference -> { KnownKanji.count }, 1 do
          2.times { KnownKanji.mark(kanjis(:taberu)) }
        end
      end

      assert kanjis(:taberu).reload.known?
      assert_equal Date.new(2026, 11, 20), kanjis(:taberu).known_mark.marked_on
    end

    test "unmark quita la marca y no falla si no existía" do
      KnownKanji.unmark(kanjis(:hito))
      KnownKanji.unmark(kanjis(:hito))

      assert_not kanjis(:hito).reload.known?
    end

    test "al eliminar el kanji se elimina su marca" do
      assert_difference -> { KnownKanji.count }, -1 do
        kanjis(:hito).destroy
      end
    end
  end
end
