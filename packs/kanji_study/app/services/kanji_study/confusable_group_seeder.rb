require "csv"

module KanjiStudy
  # Crea los grupos para distinguir de db/seeds/confusable_groups.csv. Los kanji que no
  # existen (人, 日, 目, 会…) se crean como kanji de referencia, sin semana.
  #
  # Idempotente y no destructivo: si ya hay un grupo con los mismos kanji, no se toca.
  class ConfusableGroupSeeder
    DEFAULT_CSV = Rails.root.join("db/seeds/confusable_groups.csv")
    PRACTICE_MODES = { "sí" => "card", "si" => "card", "papel" => "paper", "por confirmar" => "pending" }.freeze

    Result = Data.define(:created, :skipped, :reference_kanji)

    def self.call(...)
      new(...).call
    end

    def initialize(csv_path: DEFAULT_CSV)
      @csv_path = csv_path
    end

    def call
      created = skipped = 0
      reference_kanji = []
      existing = ConfusableGroup.includes(:kanjis).map { |group| group.kanjis.map(&:character).sort }

      ApplicationRecord.transaction do
        CSV.foreach(@csv_path, headers: true, encoding: "UTF-8") do |row|
          characters = row.fetch("par").scan(/\p{Han}/)
          if existing.include?(characters.sort)
            skipped += 1
            next
          end

          group = ConfusableGroup.create!(
            characters: characters.join("/"),
            plan_week: find_week(row.fetch("semana")),
            practice_mode: parse_practice_mode(row.fetch("tarjeta"))
          )
          existing << characters.sort
          reference_kanji.concat(group.created_kanjis.map(&:character))
          created += 1
        end
      end

      Result.new(created:, skipped:, reference_kanji:)
    end

    private

    def find_week(code)
      PlanWeek.find_by(code:) or raise ArgumentError, "la semana #{code} no existe; corre PlanSeeder primero"
    end

    def parse_practice_mode(value)
      PRACTICE_MODES.fetch(value.to_s.strip.downcase) do
        raise ArgumentError, "tarjeta desconocida: #{value.inspect} (se espera sí, papel o por confirmar)"
      end
    end
  end
end
