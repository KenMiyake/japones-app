module Srs
  # La cola de repaso de hoy: las tarjetas vencidas y las nuevas que caben en el cupo diario.
  #
  # El cupo cuenta "cosas repasables" (p. ej. kanji), no tarjetas: con un cupo de 5 entran
  # 5 kanji nuevos por día, cada uno con todas sus tarjetas (Leer y Escribir). Las nuevas se
  # eligen por `new_rank` (el orden que fija cada dominio; en kanji, el del plan).
  #
  # El día va de medianoche a medianoche en la zona horaria de la app (Santiago).
  #
  #   queue = Srs::ReviewQueue.new
  #   queue.due_cards    # vencidas, la más atrasada primero
  #   queue.new_cards    # nuevas de hoy, en orden
  #   queue.next_card    # la próxima a mostrar (primero las vencidas)
  #   queue.counts       # { due: 12, new: 10 }
  class ReviewQueue
    NEW_PER_DAY = 5

    attr_reader :now, :new_per_day, :card_types

    def initialize(now: Time.current, new_per_day: NEW_PER_DAY, card_types: nil)
      @now = now
      @new_per_day = new_per_day
      @card_types = card_types
    end

    def due_cards
      Card.due(now).of_types(card_types).by_due
    end

    # Las tarjetas nuevas de hoy:
    # - las que faltan de los repasables que ya se empezaron hoy (no gastan cupo), y
    # - todas las de los siguientes repasables por new_rank, hasta llenar el cupo.
    def new_cards
      unseen = Card.unseen.of_types(card_types).where.not(new_rank: nil)
      started = introduced_today_pairs
      slots = [ new_per_day - started.size, 0 ].max

      fresh = unseen
      started.each { |type, id| fresh = fresh.where.not(reviewable_type: type, reviewable_id: id) }
      fresh_pairs = fresh.group(:reviewable_type, :reviewable_id)
                         .order(Arel.sql("MIN(new_rank)")).limit(slots)
                         .pluck(:reviewable_type, :reviewable_id)

      pairs = started + fresh_pairs
      return Card.none if pairs.empty?

      pairs.map { |type, id| unseen.where(reviewable_type: type, reviewable_id: id) }.reduce(:or).by_new_rank
    end

    def next_card
      due_cards.first || new_cards.first
    end

    def counts
      { due: due_cards.count, new: new_cards.count }
    end

    # Cuántos repasables distintos se vieron por primera vez hoy.
    def introduced_today
      introduced_today_pairs.size
    end

    private

    # [[reviewable_type, reviewable_id], …] de lo que tuvo hoy su primer repaso.
    def introduced_today_pairs
      @introduced_today_pairs ||=
        Review.joins(:card).merge(Card.of_types(card_types))
              .where(state: "new", reviewed_at: now.beginning_of_day..now.end_of_day)
              .distinct.pluck("srs_cards.reviewable_type", "srs_cards.reviewable_id")
    end
  end
end
