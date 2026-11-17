# Punto de extensión: secciones que otros packs agregan a la página de una semana.
#
# core no depende de ningún dominio (ver docs/decisions/0001). Cada pack registra su
# partial, que recibe el local `plan_week`:
#
#   # packs/kanji_study/config/initializers/plan_week_sections.rb
#   Rails.application.config.to_prepare do
#     PlanWeekSections.register(:kanji, partial: "kanji_study/plan_weeks/section", position: 10)
#   end
#
# Se registra en to_prepare porque este módulo se recarga en desarrollo y el registro
# se vacía con él.
module PlanWeekSections
  Section = Data.define(:key, :partial, :position)

  @sections = {}

  class << self
    def register(key, partial:, position: 100)
      @sections[key] = Section.new(key:, partial:, position:)
    end

    def all
      @sections.values.sort_by(&:position)
    end

    def clear
      @sections.clear
    end
  end
end
