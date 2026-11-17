module KanjiStudy
  # Un kanji y su contenido de estudio. La semana del plan marca cuándo se estudia;
  # la lección de Minna es solo una referencia (puede faltar o no calzar con la semana).
  class Kanji < ApplicationRecord
    self.table_name = "kanjis"

    belongs_to :plan_week, optional: true
    belongs_to :lesson, optional: true
    has_many :readings, -> { order(:position, :id) },
             class_name: "KanjiStudy::KanjiReading", inverse_of: :kanji, dependent: :destroy
    has_one :known_mark, class_name: "KanjiStudy::KnownKanji", inverse_of: :kanji, dependent: :destroy

    accepts_nested_attributes_for :readings, allow_destroy: true,
                                             reject_if: ->(attrs) { attrs["kana"].blank? && attrs["okurigana"].blank? }

    validates :character, presence: true, uniqueness: true
    validate :character_is_a_single_kanji
    validates :position, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

    normalizes :character, with: ->(value) { value.strip }
    normalizes :meaning_es, :mnemonic, :notes, with: ->(value) { value.strip.presence }

    before_validation :number_readings

    scope :ordered, -> { order(:position, :character) }
    # Por semana del plan (las sin semana al final) y luego por orden dentro de la semana.
    scope :in_plan_order, -> {
      left_joins(:plan_week).order(PlanWeek.arel_table[:position].asc.nulls_last, :position, :character)
    }
    scope :in_plan_week, ->(week) { where(plan_week: week) }
    scope :without_plan_week, -> { where(plan_week_id: nil) }

    # URLs con el propio kanji: /kanjis/日
    def to_param
      character_was.presence || character
    end

    def on_readings
      readings.select(&:kind_on?)
    end

    def kun_readings
      readings.select(&:kind_kun?)
    end

    # La lección de Minna no está dentro del rango de la semana del plan.
    # Solo es un aviso: L09 está en S4 y en S5, y el aprendizaje sigue su propio camino.
    def lesson_outside_plan_week?
      return false if lesson.nil? || plan_week.nil?

      plan_week.lesson_numbers.exclude?(lesson.number)
    end

    # Campos sin completar, para mostrar qué falta.
    def missing_fields
      {
        meaning_es: meaning_es.blank?,
        readings: readings.reject(&:marked_for_destruction?).empty?,
        mnemonic: mnemonic.blank?,
        lesson: lesson.nil?
      }.select { |_field, missing| missing }.keys
    end

    def complete?
      missing_fields.empty?
    end

    def known?
      known_mark.present?
    end

    private

    # Las lecturas quedan en el orden en que aparecen en el formulario.
    def number_readings
      readings.reject(&:marked_for_destruction?).each_with_index { |reading, index| reading.position = index }
    end

    def character_is_a_single_kanji
      return if character.blank?
      return if character.match?(/\A\p{Han}\z/)

      errors.add(:character, :single_kanji)
    end
  end
end
