module Srs
  # Un repaso de una tarjeta: la respuesta y el estado de la tarjeta antes de responder.
  class Review < ApplicationRecord
    self.table_name = "srs_reviews"

    belongs_to :card, class_name: "Srs::Card", inverse_of: :reviews

    enum :rating, { again: "again", hard: "hard", good: "good", easy: "easy" }, prefix: :rated, validate: true
    enum :state, { new: "new", learning: "learning", review: "review", relearning: "relearning" },
         prefix: :was, validate: true

    validates :reviewed_at, presence: true

    scope :since, ->(time) { where(reviewed_at: time..) }
    scope :lapses, -> { rated_again }
  end
end
