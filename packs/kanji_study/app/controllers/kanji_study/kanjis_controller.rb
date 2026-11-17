module KanjiStudy
  class KanjisController < ApplicationController
    before_action :set_kanji, only: %i[show edit update destroy]

    def index
      @plan_weeks = PlanWeek.ordered
      @filter = params[:week].presence
      @kanjis = filtered_kanjis.includes(:plan_week, :lesson, :readings).in_plan_order
    end

    def show
    end

    def new
      @kanji = Kanji.new(plan_week: PlanWeek.find_by(code: params[:week]))
      @kanji.readings.build(kind: "on")
      @kanji.readings.build(kind: "kun")
    end

    def create
      @kanji = Kanji.new(kanji_params)

      if @kanji.save
        redirect_to kanji_path(@kanji), notice: "Kanji #{@kanji.character} creado."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @kanji.update(kanji_params)
        redirect_to kanji_path(@kanji), notice: "Kanji #{@kanji.character} actualizado."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @kanji.destroy!
      redirect_to kanjis_path, notice: "Kanji #{@kanji.character} eliminado.", status: :see_other
    end

    private

    def set_kanji
      @kanji = Kanji.includes(:readings, :plan_week, :lesson).find_by!(character: params[:id])
    end

    def filtered_kanjis
      case @filter
      when nil then Kanji.all
      when "none" then Kanji.without_plan_week
      else Kanji.in_plan_week(PlanWeek.find_by!(code: @filter))
      end
    end

    def kanji_params
      params.expect(kanji: [
        :character, :plan_week_id, :position, :lesson_id, :meaning_es, :mnemonic, :notes,
        readings_attributes: [ [ :id, :kind, :kana, :okurigana, :taught, :_destroy ] ]
      ])
    end
  end
end
