module KanjiStudy
  module KnownKanjisHelper
    # Clave de la sección de una semana en la cuadrícula ("S1" o "none" para los sin semana).
    def known_week_key(week)
      week&.code || "none"
    end

    # [sabidos, total] de todos los kanji, o de una semana si se pasa week: (nil = sin semana).
    def known_counts(**options)
      scope = if options.key?(:week)
        options[:week] ? Kanji.in_plan_week(options[:week]) : Kanji.without_plan_week
      else
        Kanji.all
      end
      [ scope.joins(:known_mark).count, scope.count ]
    end
  end
end
