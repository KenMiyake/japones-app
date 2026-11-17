require "csv"

module KanjiStudy
  # Crea los kanji del plan (columna "kanji" de db/seeds/plan.csv), cada uno en su semana
  # y en el orden del CSV. Requiere que las semanas existan (PlanSeeder corre antes).
  #
  # Idempotente y no destructivo: un kanji que ya existe no se toca, aunque esté en otra
  # semana o sin semana (puede haberse editado desde la app).
  class PlanKanjiSeeder
    DEFAULT_CSV = Rails.root.join("db/seeds/plan.csv")

    Result = Data.define(:created, :skipped)

    def self.call(...)
      new(...).call
    end

    def initialize(csv_path: DEFAULT_CSV)
      @csv_path = csv_path
    end

    def call
      created = skipped = 0

      ApplicationRecord.transaction do
        CSV.foreach(@csv_path, headers: true, encoding: "UTF-8") do |row|
          week = PlanWeek.find_by(code: row.fetch("semana")) or
            raise ArgumentError, "la semana #{row.fetch('semana')} no existe; corre PlanSeeder primero"

          row.fetch("kanji").split.each.with_index(1) do |character, position|
            kanji = Kanji.find_or_initialize_by(character:)
            if kanji.persisted?
              skipped += 1
            else
              kanji.update!(plan_week: week, position:)
              created += 1
            end
          end
        end
      end

      Result.new(created:, skipped:)
    end
  end
end
