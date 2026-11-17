require "test_helper"

module KanjiStudy
  class ConfusableGroupSeederTest < ActiveSupport::TestCase
    setup do
      ConfusableGroup.destroy_all
      Kanji.delete_all
      PlanWeek.delete_all
      Lesson.delete_all
      PlanSeeder.call
      PlanKanjiSeeder.call
    end

    test "crea los 22 grupos con su semana y modo de práctica" do
      result = ConfusableGroupSeeder.call

      assert_equal 22, result.created
      assert_equal({ "card" => 6, "paper" => 2, "pending" => 14 }, ConfusableGroup.group(:practice_mode).count)

      group = ConfusableGroup.joins(:plan_week).where(plan_weeks: { code: "S7" }).find { |g| g.label == "待/持/特" }
      assert group, "falta el grupo de 3 待/持/特 en S7"
    end

    test "crea los 8 kanji de referencia que no están en el plan" do
      result = ConfusableGroupSeeder.call

      assert_equal %w[人 日 目 干 会 小 大 水].sort, result.reference_kanji.sort
      assert Kanji.where(character: result.reference_kanji).all? { |kanji| kanji.plan_week.nil? }
    end

    test "es idempotente: no duplica grupos ya existentes" do
      ConfusableGroupSeeder.call
      ConfusableGroup.find { |g| g.label == "午/牛" }.update!(practice_mode: "paper")

      again = ConfusableGroupSeeder.call

      assert_equal 0, again.created
      assert_equal 22, again.skipped
      assert ConfusableGroup.find { |g| g.label == "午/牛" }.practice_paper?, "no sobrescribe lo editado"
    end

    test "falla con un valor de tarjeta desconocido, sin dejar nada a medias" do
      csv = Tempfile.new([ "pares", ".csv" ])
      csv.write("semana,par,tarjeta\nS1,人/入,sí\nS1,日/目,tal vez\n")
      csv.close

      assert_raises(ArgumentError) { ConfusableGroupSeeder.call(csv_path: csv.path) }
      assert_equal 0, ConfusableGroup.count
    ensure
      csv&.unlink
    end
  end
end
