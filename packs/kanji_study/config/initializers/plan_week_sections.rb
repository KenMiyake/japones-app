# Agrega los kanji de la semana a la página de cada semana del plan (pack core).
Rails.application.config.to_prepare do
  PlanWeekSections.register(:kanji, partial: "kanji_study/plan_weeks/section", position: 10)
  PlanWeekSections.register(:confusable_groups, partial: "kanji_study/plan_weeks/confusable_section", position: 20)
end
