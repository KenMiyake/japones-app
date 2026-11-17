# Inicio: un saludo (おかえり) y un acceso a la semana actual. Nada más.
class HomeController < ApplicationController
  def show
    @current_week = PlanWeek.current
    @next_week = PlanWeek.where(starts_on: Date.current..).ordered.first unless @current_week
  end
end
