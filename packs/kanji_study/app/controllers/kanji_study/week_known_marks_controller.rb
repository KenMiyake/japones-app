module KanjiStudy
  # Marca o desmarca de una vez todos los kanji de una semana (útil para la selección inicial).
  class WeekKnownMarksController < ApplicationController
    before_action :set_plan_week

    def create
      ApplicationRecord.transaction { week_kanjis.each { |kanji| KnownKanji.mark(kanji) } }
      respond
    end

    def destroy
      KnownKanji.where(kanji: week_kanjis).destroy_all
      respond
    end

    private

    def set_plan_week
      @plan_week = PlanWeek.find_by!(code: params[:plan_week_id])
    end

    def week_kanjis
      Kanji.in_plan_week(@plan_week)
    end

    def respond
      @kanjis = week_kanjis.includes(:known_mark).ordered
      respond_to do |format|
        format.turbo_stream { render "kanji_study/known_kanjis/week" }
        format.html { redirect_to known_kanjis_path, status: :see_other }
      end
    end
  end
end
