module KanjiStudy
  # Crea y mantiene las tarjetas de repaso (pack srs) de los kanji y los grupos.
  #
  # - Cada kanji del plan tiene dos tarjetas: Leer (read) y Escribir (write). Los kanji de
  #   referencia (sin semana) no tienen tarjetas propias.
  # - Cada grupo para distinguir en modo "tarjeta" tiene una tarjeta Distinguir (distinguish).
  # - new_rank sigue el orden del plan: semana, posición del kanji y Leer antes que Escribir.
  #   Los grupos de una semana entran después de sus kanji.
  # - Un kanji sabido pasa sus tarjetas nuevas a "en repaso", repartidas en los próximos 7
  #   días; si se desmarca y nunca se repasó, vuelven a ser nuevas.
  #
  # Es idempotente: se puede correr cuantas veces se quiera (bin/rails db:seed lo hace).
  # Ver docs/decisions/0004.
  class CardSync
    KANJI_CARD_TYPES = %w[read write].freeze
    GROUP_CARD_TYPE = "distinguish"
    WEEK_SPAN = 1000      # rangos por semana: S1 = 1000…1999, S2 = 2000…2999
    GROUPS_OFFSET = 900   # los grupos van después de los kanji de su semana
    KNOWN_SPREAD_DAYS = 7 # los sabidos se reparten en una semana

    def self.sync_all(now: Time.current)
      new(now:).sync_all
    end

    def self.sync_kanji(kanji, now: Time.current)
      new(now:).sync_kanji(kanji)
    end

    def self.sync_group(group, now: Time.current)
      new(now:).sync_group(group)
    end

    def initialize(now: Time.current, scheduler: Srs::Scheduler.new)
      @now = now
      @scheduler = scheduler
    end

    def sync_all
      ApplicationRecord.transaction do
        Kanji.includes(:plan_week).find_each { |kanji| sync_kanji(kanji) }
        ConfusableGroup.includes(:plan_week).find_each { |group| sync_group(group) }
      end
    end

    def sync_kanji(kanji)
      unless kanji.plan_week
        remove_untouched_cards(kanji)
        return
      end

      known = KnownKanji.exists?(kanji_id: kanji.id)
      KANJI_CARD_TYPES.each_with_index do |card_type, index|
        rank = kanji_rank(kanji) * 10 + index
        card = Srs::Card.for(kanji, card_type)
        card.update!(new_rank: rank) if card.new_rank != rank

        if known && card.state_new?
          @scheduler.mark_known!(card, now: @now, due_at: @now + (1 + rank % KNOWN_SPREAD_DAYS).days)
        elsif !known && marked_known_only?(card)
          @scheduler.reset!(card, now: @now)
        end
      end
    end

    def sync_group(group)
      if group.practice_card? && group.plan_week
        rank = (group.plan_week.position * WEEK_SPAN + GROUPS_OFFSET + group.id % 100) * 10
        card = Srs::Card.for(group, GROUP_CARD_TYPE)
        card.update!(new_rank: rank) if card.new_rank != rank
      else
        remove_untouched_cards(group)
      end
    end

    private

    def kanji_rank(kanji)
      kanji.plan_week.position * WEEK_SPAN + (kanji.position || GROUPS_OFFSET - 1)
    end

    # Una tarjeta graduada por "sabido" y nunca repasada de verdad.
    def marked_known_only?(card)
      !card.state_new? && card.reps.zero? && card.reviews.none?
    end

    # Borra las tarjetas que nunca se repasaron; las que tienen historial se conservan.
    def remove_untouched_cards(reviewable)
      Srs::Card.where(reviewable:).where.missing(:reviews).destroy_all
    end
  end
end
