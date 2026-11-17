require "test_helper"

module KanjiStudy
  class PendingQueryTest < ActiveSupport::TestCase
    test "sin filtro de semana usa la semana actual, o todas si hoy no cae en el plan" do
      assert_equal "S5", PendingQuery.new({}, today: Date.new(2026, 12, 15)).week
      assert_equal "all", PendingQuery.new({}, today: Date.new(2026, 1, 1)).week
    end

    test "filtra por semana y lista solo los incompletos" do
      assert_equal %w[間], PendingQuery.new(week: "S5").kanjis.map(&:character)
      assert_empty PendingQuery.new(week: "S1").kanjis
      assert_equal %w[人], PendingQuery.new(week: "none").kanjis.map(&:character)
      assert_equal %w[間 人], PendingQuery.new(week: "all").kanjis.map(&:character)
    end

    test "filtra por lección y por lo que falta" do
      assert_equal %w[間], PendingQuery.new(week: "all", lesson: "8").kanjis.map(&:character)
      assert_equal %w[人], PendingQuery.new(week: "all", missing: "lesson").kanjis.map(&:character)
      assert_nil PendingQuery.new(missing: "notas").missing
    end

    test "cuenta totales e incompletos dentro de los filtros" do
      query = PendingQuery.new(week: "all")

      assert_equal 3, query.total
      assert_equal 2, query.incomplete_count
      assert_equal({ meaning_es: 1, readings: 2, mnemonic: 2, lesson: 1 }, query.counts_by_field)
    end

    test "una semana inexistente lanza RecordNotFound" do
      assert_raises(ActiveRecord::RecordNotFound) { PendingQuery.new(week: "S99").kanjis }
    end

    test "to_params conserva los filtros activos y permite cambiar uno" do
      query = PendingQuery.new(week: "S5", missing: "readings")

      assert_equal({ week: "S5", missing: "readings" }, query.to_params)
      assert_equal({ week: "S1", missing: "readings" }, query.to_params(week: "S1"))
      assert_equal({ week: "S5" }, query.to_params(missing: nil))
    end
  end
end
