# Rutas del pack kanji_study.
scope module: :kanji_study do
  resources :kanjis do
    # Marcar / desmarcar como sabido: POST / DELETE /kanjis/食/known_mark
    resource :known_mark, only: %i[create destroy]
  end

  # Grupos para distinguir. El modo de práctica se cambia desde la tarjeta del grupo:
  # PATCH /confusable_groups/:id/practice_mode
  resources :confusable_groups, except: :show do
    resource :practice_mode, only: :update, controller: "confusable_practice_modes"
  end

  # Palabras de ejemplo (se enlazan solas con sus kanji)
  resources :words, except: :show

  # Piezas de los kanji
  resources :components, except: :show

  # Cuadrícula de kanji sabidos
  resources :known_kanjis, only: :index

  # Marcar / desmarcar todos los kanji de una semana: POST / DELETE /plan_weeks/S1/known_marks
  resources :plan_weeks, only: [] do
    resource :known_marks, only: %i[create destroy], controller: "week_known_marks"
  end
end
