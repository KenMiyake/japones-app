# Lección de Minna no Nihongo. Es una referencia al libro: el camino de aprendizaje lo
# marcan las semanas del plan (PlanWeek). Ver docs/decisions/0003.
class Lesson < ApplicationRecord
  validates :number, presence: true,
                     numericality: { only_integer: true, greater_than: 0 },
                     uniqueness: true

  scope :ordered, -> { order(:number) }

  # "L07"
  def code
    format("L%02d", number)
  end

  # Semanas del plan cuyo rango incluye esta lección (L09 está en S4 y en S5).
  def plan_weeks
    PlanWeek.covering_lesson(number)
  end
end
