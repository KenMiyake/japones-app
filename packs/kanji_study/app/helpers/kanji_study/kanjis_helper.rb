module KanjiStudy
  module KanjisHelper
    # Lectura con el okurigana atenuado (た·べる). Las que enseña Minna van en tinta plena.
    def reading_tag(reading)
      tag.span(class: [ "whitespace-nowrap", reading.taught? ? "text-sumi" : "text-sumi/45" ],
               title: (reading.taught? ? "La enseña Minna" : "No la enseña Minna")) do
        safe_join([ reading.kana, (tag.span("·#{reading.okurigana}", class: "text-sumi/40") if reading.okurigana.present?) ].compact)
      end
    end

    def missing_field_badges(kanji)
      safe_join(kanji.missing_fields.map { |field| badge(t("kanji_study.missing_fields.#{field}"), tone: :warning) }, " ")
    end

    def plan_week_options
      PlanWeek.ordered.map { |week| [ "#{week.code} · #{week.lessons_label}", week.id ] }
    end

    def lesson_options
      Lesson.ordered.map { |lesson| [ [ lesson.code, lesson.title ].compact.join(" · "), lesson.id ] }
    end

    # Para filtrar por lección: el valor es el número (7), no el id.
    def lesson_number_options
      Lesson.ordered.map { |lesson| [ [ lesson.code, lesson.title ].compact.join(" · "), lesson.number ] }
    end

    def reading_kind_options
      KanjiReading.kinds.keys.map { |kind| [ t("kanji_study.reading_kinds.#{kind}"), kind ] }
    end
  end
end
