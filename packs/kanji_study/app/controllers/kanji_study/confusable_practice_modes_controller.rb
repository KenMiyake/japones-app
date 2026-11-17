module KanjiStudy
  # Cambia el modo de práctica (tarjeta / papel / por confirmar) desde la tarjeta del grupo.
  class ConfusablePracticeModesController < ApplicationController
    def update
      @group = ConfusableGroup.includes(:kanjis).find(params[:confusable_group_id])
      @group.update!(practice_mode: params.expect(:practice_mode))

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back_or_to confusable_groups_path, status: :see_other }
      end
    rescue ArgumentError, ActiveRecord::RecordInvalid
      head :unprocessable_content
    end
  end
end
