module KanjiStudy
  # Pieza de un kanji: un carácter (亻, 宀), un nombre propio ("techo") o ambos.
  # Los nombres son los que usa el usuario en sus mnemotecnias (ver docs/decisions/0003).
  class Component < ApplicationRecord
    self.table_name = "components"

    has_many :kanji_components, class_name: "KanjiStudy::KanjiComponent", inverse_of: :component, dependent: :destroy
    has_many :kanjis, through: :kanji_components

    normalizes :character, :name, :meaning_es, with: ->(value) { value.strip.presence }

    validates :character, length: { is: 1 }, uniqueness: true, allow_nil: true
    validates :name, uniqueness: { case_sensitive: false }, allow_nil: true
    validate :character_or_name_present

    scope :ordered, -> { order(Arel.sql("COALESCE(name, character)")) }

    # Busca una pieza por lo que escribió el usuario: su carácter o su nombre.
    def self.find_by_token(token)
      token = token.to_s.strip
      return if token.blank?

      find_by(character: token) || where("lower(name) = ?", token.downcase).first
    end

    # Crea una pieza a partir de lo escrito: un solo carácter va a `character`, si no a `name`.
    def self.build_from_token(token)
      token = token.to_s.strip
      token.length == 1 ? new(character: token) : new(name: token)
    end

    # Lo que se muestra y se escribe en el formulario del kanji.
    def token
      character || name
    end

    def label
      [ character, name ].compact.join(" ")
    end

    private

    def character_or_name_present
      errors.add(:base, :character_or_name) if character.blank? && name.blank?
    end
  end
end
