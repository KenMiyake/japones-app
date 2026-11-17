require "test_helper"

class PlanWeekSectionsTest < ActiveSupport::TestCase
  setup { @registered = PlanWeekSections.all }

  teardown do
    PlanWeekSections.clear
    @registered.each { |s| PlanWeekSections.register(s.key, partial: s.partial, position: s.position) }
  end

  test "devuelve las secciones registradas ordenadas por posición" do
    PlanWeekSections.clear
    PlanWeekSections.register(:grammar, partial: "grammar/section", position: 20)
    PlanWeekSections.register(:kanji, partial: "kanji/section", position: 10)

    assert_equal %i[kanji grammar], PlanWeekSections.all.map(&:key)
  end

  test "registrar dos veces la misma clave no la duplica" do
    PlanWeekSections.clear
    2.times { PlanWeekSections.register(:kanji, partial: "kanji/section") }

    assert_equal 1, PlanWeekSections.all.size
  end
end
