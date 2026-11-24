require "test_helper"

class PlanSeederTest < ActiveSupport::TestCase
  setup do
    PlanWeek.delete_all
    Lesson.delete_all
  end

  test "crea las 25 lecciones de Minna I y las 8 semanas del plan" do
    result = PlanSeeder.call

    assert_equal 25, result.lessons_created
    assert_equal 8, result.weeks_created
    assert_equal (1..25).to_a, Lesson.ordered.pluck(:number)
    assert_equal %w[S1 S2 S3 S4 S5 S6 S7 S8], PlanWeek.ordered.pluck(:code)
  end

  test "las semanas son consecutivas desde el lunes 23/11/2026" do
    PlanSeeder.call

    assert_equal Date.new(2026, 11, 23), PlanWeek.find_by!(code: "S1").starts_on
    assert_equal Date.new(2026, 12, 7), PlanWeek.find_by!(code: "S3").starts_on
    assert_equal Date.new(2027, 1, 11), PlanWeek.find_by!(code: "S8").starts_on
  end

  test "lee el rango de lecciones y si la semana es provisional" do
    PlanSeeder.call

    s5 = PlanWeek.find_by!(code: "S5")
    assert_equal 9..11, s5.lesson_numbers
    assert s5.provisional?

    assert_equal %w[S4 S5 S7 S8], PlanWeek.where(provisional: true).ordered.pluck(:code)
  end

  test "es idempotente y no sobrescribe lo editado" do
    PlanSeeder.call
    Lesson.find_by!(number: 1).update!(title: "はじめまして")
    PlanWeek.find_by!(code: "S4").update!(provisional: false)

    result = PlanSeeder.call

    assert_equal 0, result.lessons_created
    assert_equal 0, result.weeks_created
    assert_equal 25, Lesson.count
    assert_equal "はじめまして", Lesson.find_by!(number: 1).title
    assert_not PlanWeek.find_by!(code: "S4").provisional?
  end

  test "acepta otra fecha de inicio" do
    PlanSeeder.call(starts_on: Date.new(2027, 3, 1))

    assert_equal Date.new(2027, 3, 8), PlanWeek.find_by!(code: "S2").starts_on
  end

  test "falla con un valor provisional desconocido y no deja nada a medias" do
    csv = Tempfile.new([ "plan", ".csv" ])
    csv.write("semana,lecciones,provisional,kanji\nS1,L01-L03,no,英\nS2,L04-L05,quizás,今\n")
    csv.close

    assert_raises(ArgumentError) { PlanSeeder.call(csv_path: csv.path) }
    assert_equal 0, PlanWeek.count
    assert_equal 0, Lesson.count
  ensure
    csv&.unlink
  end
end
