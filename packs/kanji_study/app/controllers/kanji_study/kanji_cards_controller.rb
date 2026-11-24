module KanjiStudy
  # Acciones sobre las tarjetas de repaso de un kanji.
  class KanjiCardsController < ApplicationController
    # "Olvidado": equivale a responder "Otra vez". La tarjeta vuelve hoy, en reaprendizaje.
    def forgot
      kanji = Kanji.find_by!(character: params[:kanji_id])
      card = kanji.srs_cards.find_by!(card_type: params[:card_type])
      label = t("kanji_study.card_types.#{card.card_type}")

      if card.state_new?
        redirect_to kanji_path(kanji), alert: "La tarjeta #{label} todavía es nueva: no hay nada que olvidar."
      else
        Srs::Scheduler.new.review!(card, :again)
        redirect_to kanji_path(kanji), notice: "#{kanji.character} (#{label}) marcado como olvidado: vuelve hoy."
      end
    end
  end
end
