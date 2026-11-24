module Srs
  # Una tarjeta de repaso: algo repasable (reviewable) + un tipo de tarjeta, con su estado
  # FSRS. El cálculo de fechas lo hace Srs::Scheduler; este modelo solo guarda el estado.
  class Card < ApplicationRecord
    self.table_name = "srs_cards"

    belongs_to :reviewable, polymorphic: true
    has_many :reviews, -> { order(:reviewed_at, :id) }, class_name: "Srs::Review",
                                                        inverse_of: :card, dependent: :delete_all

    # new: nunca repasada · learning: primeros pasos (minutos) · review: repaso a largo plazo
    # relearning: olvidada en repaso, vuelve a los pasos cortos
    enum :state, { new: "new", learning: "learning", review: "review", relearning: "relearning" },
         prefix: :state, validate: true

    validates :card_type, presence: true, uniqueness: { scope: %i[reviewable_type reviewable_id] }
    validates :due_at, presence: true

    attribute :due_at, :datetime, default: -> { Time.current }

    scope :due, ->(now = Time.current) { where.not(state: "new").where(due_at: ..now) }
    scope :unseen, -> { where(state: "new") }
    scope :by_due, -> { order(:due_at, :id) }
    scope :by_new_rank, -> { order(arel_table[:new_rank].asc.nulls_last, :id) }
    scope :of_types, ->(types) { types ? where(card_type: Array(types).map(&:to_s)) : all }

    # Vuelve a pedir la tarjeta (o crea una nueva) para algo repasable y un tipo de tarjeta.
    def self.for(reviewable, card_type)
      find_or_create_by!(reviewable:, card_type: card_type.to_s)
    end
  end
end
