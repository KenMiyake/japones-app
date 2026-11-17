module KanjiStudy
  # Marca o desmarca un kanji como sabido. Con Turbo responde con streams que reemplazan
  # solo la ficha y los contadores; sin JS, vuelve a la página anterior.
  class KnownMarksController < ApplicationController
    before_action :set_kanji

    def create
      KnownKanji.mark(@kanji)
      respond
    end

    def destroy
      KnownKanji.unmark(@kanji)
      respond
    end

    private

    def set_kanji
      @kanji = Kanji.includes(:plan_week).find_by!(character: params[:kanji_id])
    end

    def respond
      @kanji.reload
      respond_to do |format|
        format.turbo_stream { render "kanji_study/known_kanjis/toggle" }
        format.html { redirect_back_or_to known_kanjis_path, status: :see_other }
      end
    end
  end
end
