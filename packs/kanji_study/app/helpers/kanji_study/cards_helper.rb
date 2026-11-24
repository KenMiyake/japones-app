module KanjiStudy
  module CardsHelper
    # "nueva", "pendiente", "hoy a las 14:30", "mañana", "en 4 días (28 nov)"
    def card_due_label(card, now: Time.current)
      return "aún no entra al repaso" if card.state_new?
      return "pendiente" if card.due_at <= now

      days = (card.due_at.to_date - now.to_date).to_i
      case days
      when 0 then "hoy a las #{l(card.due_at, format: '%H:%M')}"
      when 1 then "mañana"
      else "en #{days} días (#{l(card.due_at.to_date, format: '%-d %b')})"
      end
    end

    def card_state_label(card)
      t("srs.states.#{card.state}")
    end

    def card_type_label(card)
      t("kanji_study.card_types.#{card.card_type}")
    end
  end
end
