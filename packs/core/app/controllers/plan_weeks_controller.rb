class PlanWeeksController < ApplicationController
  def index
    @plan_weeks = PlanWeek.ordered
  end

  def show
    @plan_week = PlanWeek.find_by!(code: params[:id])
    @lessons = @plan_week.lessons
  end
end
