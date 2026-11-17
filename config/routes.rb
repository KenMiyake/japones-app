Rails.application.routes.draw do
  # Salud de la app (load balancers, monitoreo).
  get "up" => "rails/health#show", as: :rails_health_check

  # Rutas de cada pack: packs/<pack>/config/routes/<pack>.rb (ver docs/decisions/0001).
  draw(:core)
  draw(:kanji_study)

  root "home#show"
end
