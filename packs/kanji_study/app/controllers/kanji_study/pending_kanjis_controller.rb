module KanjiStudy
  # Pendientes: los kanji que faltan por completar, con edición en la misma fila.
  #
  # Cada fila vive en un Turbo Frame. "Completar" pide `edit`, que devuelve el formulario
  # dentro del mismo frame; al guardar, `update` responde con Turbo Streams que reemplazan
  # la fila y el resumen. `show` devuelve la fila (sirve para "Cancelar").
  class PendingKanjisController < ApplicationController
    before_action :set_query
    before_action :set_kanji, only: %i[show edit update]

    def index
      @plan_weeks = PlanWeek.ordered
    end

    def show
      render partial: "kanji_study/pending_kanjis/row", locals: { kanji: @kanji, query: @query }
    end

    def edit
    end

    def update
      if @kanji.update(kanji_params)
        @kanji = Kanji.includes(:readings, :lesson, :plan_week).find(@kanji.id) # lecturas tal como quedaron
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to pending_kanjis_path(@query.to_params), notice: "Kanji #{@kanji.character} actualizado." }
        end
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_query
      @query = PendingQuery.new(params.permit(:week, :lesson, :missing))
    end

    def set_kanji
      @kanji = Kanji.includes(:readings, :lesson, :plan_week).find_by!(character: params[:id])
    end

    def kanji_params
      params.expect(kanji: %i[meaning_es on_readings_text kun_readings_text lesson_id mnemonic])
    end
  end
end
