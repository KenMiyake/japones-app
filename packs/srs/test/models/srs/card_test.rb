require "test_helper"

module Srs
  # El motor es genérico: en estos tests una Lesson (de core) hace de "algo repasable".
  class CardTest < ActiveSupport::TestCase
    test "Card.for crea la tarjeta una sola vez por repasable y tipo" do
      card = Card.for(lessons(:l01), :read)

      assert card.state_new?
      assert_equal "read", card.card_type
      assert_equal card, Card.for(lessons(:l01), "read")
      assert_not_equal card, Card.for(lessons(:l01), :write)
    end

    test "no puede haber dos tarjetas del mismo tipo para lo mismo" do
      Card.for(lessons(:l01), :read)

      duplicate = Card.new(reviewable: lessons(:l01), card_type: "read")
      assert_not duplicate.valid?
    end

    test "due trae solo tarjetas ya vistas cuyo repaso venció; unseen las nuevas" do
      now = Time.zone.local(2026, 11, 24, 10)
      vencida = Card.create!(reviewable: lessons(:l01), card_type: "read", state: "review", due_at: now - 1.hour)
      futura = Card.create!(reviewable: lessons(:l08), card_type: "read", state: "review", due_at: now + 1.day)
      nueva = Card.create!(reviewable: lessons(:l09), card_type: "read", due_at: now - 1.day)

      assert_equal [ vencida ], Card.due(now).to_a
      assert_equal [ nueva ], Card.unseen.to_a
      assert_not_includes Card.due(now), futura
    end

    test "el estado solo admite los cuatro de FSRS" do
      assert_not Card.new(reviewable: lessons(:l01), card_type: "read", state: "suspendida").valid?
    end

    test "al eliminar la tarjeta se eliminan sus repasos" do
      card = Card.for(lessons(:l01), :read)
      Scheduler.new.review!(card, :good)

      assert_difference -> { Review.count }, -1 do
        card.destroy
      end
    end
  end
end
