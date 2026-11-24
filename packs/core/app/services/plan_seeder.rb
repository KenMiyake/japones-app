require "csv"

# Carga las lecciones de Minna I (L01–L25) y las semanas del plan desde db/seeds/plan.csv.
#
# Es idempotente y no destructivo: crea lo que falta y nunca sobrescribe lo existente,
# así que se puede volver a correr sin perder lo que se editó desde la app.
class PlanSeeder
  DEFAULT_CSV = Rails.root.join("db/seeds/plan.csv")
  DEFAULT_STARTS_ON = Date.new(2026, 11, 23) # lunes de la S1 (semana ISO 48)
  LESSON_NUMBERS = 1..25 # Minna no Nihongo I

  Result = Data.define(:lessons_created, :weeks_created)

  def self.call(...)
    new(...).call
  end

  def initialize(csv_path: DEFAULT_CSV, starts_on: DEFAULT_STARTS_ON)
    @csv_path = csv_path
    @starts_on = starts_on
  end

  def call
    ApplicationRecord.transaction do
      Result.new(lessons_created: seed_lessons, weeks_created: seed_weeks)
    end
  end

  private

  def seed_lessons
    existing = Lesson.where(number: LESSON_NUMBERS).pluck(:number)
    missing = LESSON_NUMBERS.to_a - existing
    missing.each { |number| Lesson.create!(number:) }
    missing.size
  end

  def seed_weeks
    rows.each_with_index.count do |row, index|
      week = PlanWeek.find_or_initialize_by(code: row.fetch("semana"))
      next false if week.persisted?

      first_lesson, last_lesson = parse_lessons(row.fetch("lecciones"))
      week.update!(
        position: index + 1,
        starts_on: @starts_on + (7 * index),
        first_lesson:,
        last_lesson:,
        provisional: parse_yes_no(row.fetch("provisional"))
      )
    end
  end

  def rows
    CSV.read(@csv_path, headers: true, encoding: "UTF-8")
  end

  # "L01-L03" => [1, 3]; "L12" => [12, 12]
  def parse_lessons(value)
    numbers = value.scan(/\d+/).map(&:to_i)
    raise ArgumentError, "rango de lecciones inválido: #{value.inspect}" unless numbers.size.in?(1..2)

    [ numbers.first, numbers.last ]
  end

  def parse_yes_no(value)
    case value.to_s.strip.downcase
    when "sí", "si" then true
    when "no" then false
    else raise ArgumentError, "se esperaba sí/no: #{value.inspect}"
    end
  end
end
