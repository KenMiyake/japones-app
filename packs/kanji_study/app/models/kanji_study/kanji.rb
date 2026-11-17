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
    has_many :confusable_members, class_name: "KanjiStudy::ConfusableMember", inverse_of: :kanji, dependent: :destroy
    has_many :confusable_groups, through: :confusable_members
    has_many :word_kanjis, class_name: "KanjiStudy::WordKanji", inverse_of: :kanji, dependent: :destroy
    has_many :words, through: :word_kanjis
    has_many :kanji_components, -> { order(:position) }, class_name: "KanjiStudy::KanjiComponent",
             inverse_of: :kanji, dependent: :destroy, autosave: true
    has_many :components, through: :kanji_components

    accepts_nested_attributes_for :readings, allow_destroy: true,
                                             reject_if: ->(attrs) { attrs["kana"].blank? && attrs["okurigana"].blank? }

    validates :character, presence: true, uniqueness: true
    validate :character_is_a_single_kanji
    validates :position, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

    normalizes :character, with: ->(value) { value.strip }
    normalizes :meaning_es, :mnemonic, :notes, with: ->(value) { value.strip.presence }

    before_validation :apply_readings_text, if: -> { @readings_text }
    before_validation :number_readings, unless: -> { @readings_text }
    after_save :relink_words, if: :saved_change_to_character?
    after_save { @readings_text = nil }
    before_save :sync_components, if: -> { @component_tokens }
    after_save :forget_component_tokens

    attr_reader :created_components

    scope :ordered, -> { order(:position, :character) }
    # Por semana del plan (las sin semana al final) y luego por orden dentro de la semana.
    scope :in_plan_order, -> {
      left_joins(:plan_week).order(PlanWeek.arel_table[:position].asc.nulls_last, :position, :character)
    }
    scope :in_plan_week, ->(week) { where(plan_week: week) }
    scope :without_plan_week, -> { where(plan_week_id: nil) }

    # Lo que falta completar (ver missing_fields). Se combinan con `or` en `incomplete`.
    scope :missing_meaning_es, -> { where(meaning_es: nil) }
    scope :missing_readings, -> { where.not(id: KanjiReading.select(:kanji_id)) }
    scope :missing_mnemonic, -> { where(mnemonic: nil) }
    scope :missing_lesson, -> { where(lesson_id: nil) }
    scope :incomplete, -> { missing_meaning_es.or(missing_readings).or(missing_mnemonic).or(missing_lesson) }

    MISSING_FIELDS = %i[meaning_es readings mnemonic lesson].freeze

    def self.missing(field)
      raise ArgumentError, "campo desconocido: #{field}" unless MISSING_FIELDS.include?(field.to_sym)

      public_send(:"missing_#{field}")
    end

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

    # Lecturas como texto, para completarlas rápido: on "ショク、ジキ", kun "た.べる、く.う"
    # (el punto separa el okurigana). Al guardar se conservan las lecturas que ya existían
    # (con su marca "la enseña Minna"), se agregan las nuevas y se quitan las que faltan.
    def on_readings_text
      @readings_text&.fetch("on", nil) || on_readings.map(&:kana).join("、")
    end

    def kun_readings_text
      @readings_text&.fetch("kun", nil) ||
        kun_readings.map { |r| [ r.kana, r.okurigana ].compact.join(".") }.join("、")
    end

    def on_readings_text=(text)
      (@readings_text ||= {})["on"] = text.to_s
    end

    def kun_readings_text=(text)
      (@readings_text ||= {})["kun"] = text.to_s
    end

    # Piezas como texto (carácter o nombre), tal como se escriben en el formulario.
    # Al guardar, las que no existen se crean y quedan en `created_components`.
    def component_tokens
      @component_tokens || components.map(&:token)
    end

    def component_tokens=(tokens)
      @component_tokens = Array(tokens).map { |token| token.to_s.strip }.compact_blank.uniq
    end

    private

    # Un kanji nuevo (o con otro carácter) se enlaza con las palabras que ya lo contenían,
    # y deja de estar enlazado a las que contienen el carácter anterior.
    def relink_words
      saved_change_to_character.compact.uniq.each do |character|
        Word.containing(character).find_each(&:link_kanjis!)
      end
    end

    def sync_components
      @created_components = []
      components = @component_tokens.map do |token|
        Component.find_by_token(token) ||
          Component.build_from_token(token).tap { |component| component.save! && @created_components << component }
      end.uniq

      existing = kanji_components.index_by(&:component_id)
      self.kanji_components = components.each_with_index.map do |component, position|
        link = existing[component.id] || KanjiComponent.new(component:)
        link.position = position
        link
      end
    end

    def forget_component_tokens
      return unless @component_tokens

      @component_tokens = nil
      association(:components).reset
    end

    # Aplica on_readings_text / kun_readings_text: reutiliza las lecturas iguales, crea las
    # nuevas, marca para borrar las que ya no están y numera en el orden escrito (on, luego kun).
    def apply_readings_text
      position = 0
      %w[on kun].each do |kind|
        current = readings.select { |r| r.kind == kind && !r.marked_for_destruction? }
        list = if @readings_text.key?(kind)
          wanted = parse_readings_text(@readings_text[kind])
          kept = wanted.map do |kana, okurigana|
            current.find { |r| r.kana == kana && r.okurigana == okurigana } ||
              readings.build(kind:, kana:, okurigana:)
          end.uniq
          (current - kept).each(&:mark_for_destruction)
          kept
        else
          current
        end
        list.each { |reading| reading.position = (position += 1) - 1 }
      end
    end

    # "た.べる、く.う" → [["た", "べる"], ["く", "う"]]
    def parse_readings_text(text)
      text.split(/[、,，\s]+/).compact_blank.map do |token|
        kana, okurigana = token.split(".", 2)
        [ kana.delete("・"), okurigana.presence ]
      end.uniq
    end

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
