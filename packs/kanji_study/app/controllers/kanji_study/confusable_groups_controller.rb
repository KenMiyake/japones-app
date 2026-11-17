module KanjiStudy
  class ConfusableGroupsController < ApplicationController
    before_action :set_group, only: %i[edit update destroy]

    def index
      @groups_by_week = ConfusableGroup.includes(:plan_week, :kanjis).in_plan_order.group_by(&:plan_week)
    end

    def new
      @group = ConfusableGroup.new(plan_week: PlanWeek.find_by(code: params[:week]))
    end

    def create
      @group = ConfusableGroup.new(group_params)

      if @group.save
        redirect_to confusable_groups_path, notice: saved_notice("creado")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @group.update(group_params)
        redirect_to confusable_groups_path, notice: saved_notice("actualizado")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      label = @group.label
      @group.destroy!
      redirect_to confusable_groups_path, notice: "Grupo #{label} eliminado.", status: :see_other
    end

    private

    def set_group
      @group = ConfusableGroup.includes(:kanjis).find(params[:id])
    end

    def group_params
      params.expect(confusable_group: %i[characters plan_week_id practice_mode hint])
    end

    def saved_notice(verb)
      notice = "Grupo #{@group.label} #{verb}."
      created = @group.created_kanjis.to_a.map(&:character)
      created.any? ? "#{notice} Kanji de referencia creados: #{created.join(' ')}." : notice
    end
  end
end
