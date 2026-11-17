# Rutas del pack kanji_study.
scope module: :kanji_study do
  resources :kanjis do
    # Marcar / desmarcar como sabido: POST / DELETE /kanjis/食/known_mark
    resource :known_mark, only: %i[create destroy]
  end

  # Cuadrícula de kanji sabidos
  resources :known_kanjis, only: :index

  # Marcar / desmarcar todos los kanji de una semana: POST / DELETE /plan_weeks/S1/known_marks
  resources :plan_weeks, only: [] do
    resource :known_marks, only: %i[create destroy], controller: "week_known_marks"
  end
end
