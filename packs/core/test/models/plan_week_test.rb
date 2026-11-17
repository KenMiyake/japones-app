require "test_helper"

class PlanWeekTest < ActiveSupport::TestCase
  def build_week(**attrs)
    PlanWeek.new({ code: "S9", position: 9, starts_on: Date.new(2027, 1, 11),
                   first_lesson: 18, last_lesson: 19 }.merge(attrs))
  end

  test "es válida con los datos mínimos" do
    assert build_week.valid?
  end

  test "el código tiene la forma S<n> y es único" do
    assert_not build_week(code: "semana 9").valid?
    assert_not build_week(code: "S1").valid?
  end

  test "la posición es única" do
    assert_not build_week(position: 1).valid?
  end

  test "la última lección no puede ser anterior a la primera" do
    week = build_week(first_lesson: 19, last_lesson: 18)

    assert_not week.valid?
    assert week.errors.added?(:last_lesson, :greater_than_or_equal_to, count: 19)
  end

  test "la semana dura de lunes a domingo" do
    week = plan_weeks(:s1)

    assert_equal Date.new(2026, 11, 22), week.ends_on
    assert week.current?(Date.new(2026, 11, 16))
    assert week.current?(Date.new(2026, 11, 22))
    assert_not week.current?(Date.new(2026, 11, 23))
  end

  test "current encuentra la semana que contiene la fecha" do
    assert_equal plan_weeks(:s4), PlanWeek.current(Date.new(2026, 12, 10))
    assert_nil PlanWeek.current(Date.new(2026, 11, 1))
  end

  test "lessons_label muestra el rango o una sola lección" do
    assert_equal "L01–L03", plan_weeks(:s1).lessons_label
    assert_equal "L12", build_week(first_lesson: 12, last_lesson: 12).lessons_label
  end

  test "lessons devuelve solo las lecciones del rango, en orden" do
    assert_equal [ 8, 9 ], plan_weeks(:s4).lessons.map(&:number)
  end

  test "covering_lesson incluye los extremos del rango" do
    assert_equal %w[S4 S5], PlanWeek.covering_lesson(9).ordered.map(&:code)
    assert_equal %w[S5], PlanWeek.covering_lesson(11).map(&:code)
    assert_empty PlanWeek.covering_lesson(25)
  end

  test "to_param usa el código" do
    assert_equal "S4", plan_weeks(:s4).to_param
  end
end
