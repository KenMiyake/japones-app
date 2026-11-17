require "test_helper"

module KanjiStudy
  class PlanKanjiSeederTest < ActiveSupport::TestCase
    setup do
      Kanji.delete_all
      PlanWeek.delete_all
      Lesson.delete_all
      PlanSeeder.call
    end

    test "crea los 196 kanji del plan, cada uno en su semana y en orden" do
      result = PlanKanjiSeeder.call

      assert_equal 196, result.created
      assert_equal 196, Kanji.count

      s1 = Kanji.in_plan_week(PlanWeek.find_by!(code: "S1")).ordered
      assert_equal 18, s1.size
      assert_equal %w[英 新 場], s1.first(3).map(&:character)
      assert_equal (1..18).to_a, s1.map(&:position)

      assert_equal "S8", Kanji.find_by!(character: "残").plan_week.code
    end

    test "es idempotente y no mueve kanji existentes" do
      Kanji.create!(character: "聞", meaning_es: "oír")

      result = PlanKanjiSeeder.call
      assert_equal 195, result.created
      assert_equal 1, result.skipped

      kanji = Kanji.find_by!(character: "聞")
      assert_nil kanji.plan_week
      assert_equal "oír", kanji.meaning_es

      again = PlanKanjiSeeder.call
      assert_equal 0, again.created
      assert_equal 196, again.skipped
    end

    test "falla si la semana no existe, sin dejar nada a medias" do
      PlanWeek.find_by!(code: "S8").destroy

      assert_raises(ArgumentError) { PlanKanjiSeeder.call }
      assert_equal 0, Kanji.count
    end
  end
end
