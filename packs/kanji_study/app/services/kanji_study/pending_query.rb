module KanjiStudy
  # Kanji por completar según los filtros de la pantalla de pendientes:
  #
  #   week:    código de semana ("S3"), "all" (todas) o "none" (sin semana).
  #            Si no viene, la semana actual (o todas si hoy no cae en el plan).
  #   lesson:  número de lección de Minna (7).
  #   missing: lo que falta: meaning_es, readings, mnemonic o lesson.
  class PendingQuery
    attr_reader :week, :lesson, :missing

    # Acepta los filtros como hash (params del controlador) o como argumentos con nombre.
    def initialize(params = {}, today: Date.current, **filters)
      params = params.to_h.symbolize_keys.merge(filters)
      @week = params[:week].presence || PlanWeek.current(today)&.code || "all"
      @lesson = params[:lesson].presence&.to_i
      @missing = params[:missing].presence_in(Kanji::MISSING_FIELDS.map(&:to_s))
    end

    def plan_week
      return @plan_week if defined?(@plan_week)

      @plan_week = PlanWeek.find_by!(code: week) unless week.in?(%w[all none])
    end

    # Todos los kanji dentro de la semana y la lección elegidas (completos o no).
    def scope
      relation = Kanji.all
      relation = case week
      when "all" then relation
      when "none" then relation.without_plan_week
      else relation.in_plan_week(plan_week)
      end
      relation = relation.where(lesson: Lesson.where(number: lesson)) if lesson
      relation
    end

    def kanjis
      relation = missing ? scope.missing(missing) : scope.incomplete
      relation.includes(:readings, :lesson, :plan_week).in_plan_order
    end

    def total
      scope.count
    end

    def incomplete_count
      scope.incomplete.count
    end

    # { meaning_es: 12, readings: 20, mnemonic: 26, lesson: 26 }
    def counts_by_field
      Kanji::MISSING_FIELDS.index_with { |field| scope.missing(field).count }
    end

    # Los filtros activos, para armar links y formularios que los conserven.
    def to_params(**overrides)
      { week:, lesson:, missing: }.merge(overrides).compact_blank
    end
  end
end
