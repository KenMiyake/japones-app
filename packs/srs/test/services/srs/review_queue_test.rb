require "test_helper"

module Srs
  # Lecciones (core) hacen de "repasables"; cada una con tarjetas read y write.
  class ReviewQueueTest < ActiveSupport::TestCase
    setup do
      @now = Time.zone.local(2026, 11, 24, 10)
      @cards = {}
      [ :l01, :l08, :l09, :l10 ].each_with_index do |lesson, i|
        %w[read write].each_with_index do |type, j|
          @cards[[ lesson, type ]] = Card.create!(reviewable: lessons(lesson), card_type: type,
                                                  new_rank: (i + 1) * 10 + j, due_at: @now)
        end
      end
    end

    test "las nuevas entran por repasable, con todas sus tarjetas, en orden de new_rank" do
      queue = ReviewQueue.new(now: @now, new_per_day: 2)

      assert_equal [ [ :l01, "read" ], [ :l01, "write" ], [ :l08, "read" ], [ :l08, "write" ] ],
                   queue.new_cards.map { |c| [ lesson_key(c), c.card_type ] }
    end

    test "el cupo descuenta los repasables ya vistos hoy" do
      Scheduler.new.review!(@cards[[ :l01, "read" ]], :good, now: @now - 1.hour)

      queue = ReviewQueue.new(now: @now, new_per_day: 2)

      assert_equal 1, queue.introduced_today
      # Queda 1 cupo: la tarjeta write de l01 (ya empezada hoy) viene sin gastarlo, y entra l08.
      assert_equal [ [ :l01, "write" ], [ :l08, "read" ], [ :l08, "write" ] ],
                   queue.new_cards.map { |c| [ lesson_key(c), c.card_type ] }
    end

    test "lo visto ayer no gasta el cupo de hoy" do
      Scheduler.new.review!(@cards[[ :l01, "read" ]], :good, now: @now - 1.day)

      assert_equal 0, ReviewQueue.new(now: @now).introduced_today
    end

    test "sin cupo no hay nuevas" do
      assert_empty ReviewQueue.new(now: @now, new_per_day: 0).new_cards
    end

    test "las vencidas vienen primero y por fecha; next_card prioriza vencidas" do
      older = @cards[[ :l09, "read" ]]
      newer = @cards[[ :l10, "read" ]]
      older.update!(state: "review", due_at: @now - 2.days)
      newer.update!(state: "review", due_at: @now - 1.hour)

      queue = ReviewQueue.new(now: @now)

      assert_equal [ older, newer ], queue.due_cards.to_a
      assert_equal older, queue.next_card
    end

    test "filtra por tipos de tarjeta" do
      queue = ReviewQueue.new(now: @now, new_per_day: 1, card_types: :read)

      assert_equal [ @cards[[ :l01, "read" ]] ], queue.new_cards.to_a
    end

    test "counts cuenta vencidas y nuevas de hoy" do
      @cards[[ :l10, "write" ]].update!(state: "review", due_at: @now - 1.minute)

      assert_equal({ due: 1, new: 6 }, ReviewQueue.new(now: @now, new_per_day: 3).counts)
    end

    test "las tarjetas sin new_rank nunca entran como nuevas" do
      Card.update_all(new_rank: nil)

      assert_empty ReviewQueue.new(now: @now).new_cards
    end

    private

    def lesson_key(card)
      { lessons(:l01).id => :l01, lessons(:l08).id => :l08, lessons(:l09).id => :l09, lessons(:l10).id => :l10 }
        .fetch(card.reviewable_id)
    end
  end
end
