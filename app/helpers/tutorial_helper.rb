# Datos del tutorial para el controlador Stimulus "tour", tomados de I18n
# (config/locales/tutorial.<idioma>.yml). El JavaScript no tiene textos propios.
module TutorialHelper
  def tutorial_config
    {
      steps: Array(t("tutorial.steps")).map { |step| step.slice(:key, :target, :title, :body) },
      labels: t("tutorial.controls")
    }
  end

  # El tutorial arranca solo la primera vez, en el inicio.
  def tutorial_autostart?
    current_page?(root_path)
  end
end
