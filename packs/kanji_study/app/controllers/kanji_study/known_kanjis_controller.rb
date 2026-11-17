module KanjiStudy
  # Cuadrícula para marcar qué kanji ya se saben.
  class KnownKanjisController < ApplicationController
    def index
      @kanjis_by_week = Kanji.includes(:plan_week, :known_mark).in_plan_order.group_by(&:plan_week)
    end
  end
end
