# Semana del plan de estudio (S1–S8): el camino de aprendizaje. Cubre un rango de lecciones
# de Minna, que puede solaparse con el de otra semana (L09 está en S4 y en S5).
class PlanWeek < ApplicationRecord
  CODE_FORMAT = /\AS\d+\z/

  validates :code, presence: true, uniqueness: true, format: { with: CODE_FORMAT }
  validates :position, presence: true, uniqueness: true,
                       numericality: { only_integer: true, greater_than: 0 }
  validates :starts_on, presence: true
  validates :first_lesson, :last_lesson, presence: true,
                                         numericality: { only_integer: true, greater_than: 0 }
  validate :lesson_range_is_ordered

  scope :ordered, -> { order(:position) }
  scope :covering_lesson, ->(number) { where(first_lesson: ..number, last_lesson: number..) }

  def self.current(today = Date.current)
    where(starts_on: (today - 6)..today).first
  end

  # URLs con el código: /plan_weeks/S3
  def to_param
    code
  end

  def ends_on
    starts_on + 6
  end

  def current?(today = Date.current)
    (starts_on..ends_on).cover?(today)
  end

  def lesson_numbers
    first_lesson..last_lesson
  end

  def lessons
    Lesson.where(number: lesson_numbers).ordered
  end

  # "L06–L07" o "L12" si la semana cubre una sola lección.
  def lessons_label
    [ first_lesson, last_lesson ].uniq.map { |n| format("L%02d", n) }.join("–")
  end

  private

  def lesson_range_is_ordered
    return if first_lesson.blank? || last_lesson.blank?
    return if last_lesson >= first_lesson

    errors.add(:last_lesson, :greater_than_or_equal_to, count: first_lesson)
  end
end
