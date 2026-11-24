module KanjiStudy
  # Kanji que se confunden y se practican juntos (人/入, 待/持/特).
  #
  # Los miembros se escriben como texto en `characters` ("待/持/特" o "待持特"). Al guardar,
  # los kanji que no existen se crean como kanji de referencia (sin semana) y quedan en
  # `created_kanjis` para avisarlo.
  class ConfusableGroup < ApplicationRecord
    self.table_name = "confusable_groups"

    belongs_to :plan_week, optional: true
    has_many :members, -> { order(:position) },
             class_name: "KanjiStudy::ConfusableMember", inverse_of: :confusable_group,
             dependent: :destroy, autosave: true # autosave: guarda también el nuevo orden de los existentes
    has_many :kanjis, through: :members
    # Tarjeta Distinguir (pack srs), solo en modo "tarjeta". Ver KanjiStudy::CardSync.
    has_many :srs_cards, as: :reviewable, class_name: "Srs::Card", dependent: :destroy

    # card: tiene tarjeta · paper: se practica en papel · pending: por confirmar
    enum :practice_mode, { card: "card", paper: "paper", pending: "pending" },
         prefix: :practice, default: :pending, validate: true

    normalizes :hint, with: ->(value) { value.strip.presence }

    validate :has_at_least_two_kanji
    before_save :sync_members, if: -> { @parsed_characters }
    after_save :forget_typed_characters
    after_save :sync_cards, if: -> { previously_new_record? || saved_change_to_practice_mode? || saved_change_to_plan_week_id? }

    scope :in_plan_order, -> {
      left_joins(:plan_week).order(PlanWeek.arel_table[:position].asc.nulls_last, :id)
    }

    attr_reader :created_kanjis

    def characters
      @characters || kanjis.map(&:character).join("/")
    end

    def characters=(value)
      @characters = value.to_s
      @parsed_characters = @characters.scan(/\p{Han}/).uniq
    end

    # "待/持/特"
    def label
      characters_list.join("/")
    end

    def characters_list
      @parsed_characters || kanjis.map(&:character)
    end

    private

    def has_at_least_two_kanji
      errors.add(:characters, :too_few_kanji) if characters_list.size < 2
    end

    def sync_members
      @created_kanjis = []
      kanjis = @parsed_characters.map do |character|
        Kanji.find_or_create_by!(character:) { |kanji| @created_kanjis << kanji }
      end

      existing = members.index_by(&:kanji_id)
      self.members = kanjis.each_with_index.map do |kanji, position|
        member = existing[kanji.id] || ConfusableMember.new(kanji:)
        member.position = position
        member
      end
    end

    def sync_cards
      CardSync.sync_group(self)
    end

    # Tras guardar, los miembros mandan: se descarta el texto escrito y se recarga `kanjis`.
    def forget_typed_characters
      @characters = @parsed_characters = nil
      association(:kanjis).reset
    end
  end
end
