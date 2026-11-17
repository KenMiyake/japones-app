module KanjiStudy
  # Una lectura de un kanji. On'yomi en katakana (ジン), kun'yomi en hiragana (た + べる).
  # Relación 1‑N: lo interesante (okurigana, si Minna la enseña) depende del par kanji–lectura.
  class KanjiReading < ApplicationRecord
    self.table_name = "kanji_readings"

    KATAKANA = /\A[\p{Katakana}ー]+\z/
    HIRAGANA = /\A[\p{Hiragana}ー]+\z/

    belongs_to :kanji, class_name: "KanjiStudy::Kanji", inverse_of: :readings

    enum :kind, { on: "on", kun: "kun" }, prefix: true, validate: true

    validates :kana, presence: true
    validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validate :kana_matches_kind
    validate :okurigana_only_for_kun

    normalizes :kana, :okurigana, with: ->(value) { value.strip.delete(".・").presence }

    # "た·べる" para mostrar dónde empieza el okurigana; "ショク" para on'yomi.
    def to_s
      okurigana.present? ? "#{kana}·#{okurigana}" : kana
    end

    private

    def kana_matches_kind
      return if kana.blank? || kind.blank?

      if kind_on? && !kana.match?(KATAKANA)
        errors.add(:kana, :katakana_required)
      elsif kind_kun? && !kana.match?(HIRAGANA)
        errors.add(:kana, :hiragana_required)
      end
    end

    def okurigana_only_for_kun
      return if okurigana.blank?

      if kind_on?
        errors.add(:okurigana, :only_for_kun)
      elsif !okurigana.match?(HIRAGANA)
        errors.add(:okurigana, :hiragana_required)
      end
    end
  end
end
