require "test_helper"

class LessonTest < ActiveSupport::TestCase
  test "es válida con un número positivo y sin título" do
    assert Lesson.new(number: 12).valid?
  end

  test "exige un número entero positivo y único" do
    assert_not Lesson.new(number: nil).valid?
    assert_not Lesson.new(number: 0).valid?
    assert_not Lesson.new(number: 2.5).valid?

    duplicate = Lesson.new(number: lessons(:l01).number)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:number], "ya está en uso"
  end

  test "code tiene dos dígitos" do
    assert_equal "L01", lessons(:l01).code
    assert_equal "L10", lessons(:l10).code
  end

  test "plan_weeks devuelve todas las semanas que cubren la lección" do
    assert_equal %w[S4 S5], lessons(:l09).plan_weeks.ordered.map(&:code)
    assert_equal %w[S4], lessons(:l08).plan_weeks.map(&:code)
  end
end
