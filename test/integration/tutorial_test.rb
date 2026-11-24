require "test_helper"

class TutorialTest < ActionDispatch::IntegrationTest
  def tour_config
    JSON.parse(css_select("body").first["data-tour-config-value"])
  end

  test "los textos del tutorial vienen completos de I18n (sin traducciones faltantes)" do
    steps = I18n.t("tutorial.steps")

    assert_operator steps.size, :>=, 5
    steps.each do |step|
      assert step[:key].present?, "paso sin key: #{step.inspect}"
      assert step[:title].present?, "paso #{step[:key]} sin título"
      assert step[:body].present?, "paso #{step[:key]} sin texto"
    end
    %i[next previous skip finish progress].each do |label|
      assert I18n.exists?("tutorial.controls.#{label}"), "falta tutorial.controls.#{label}"
    end
  end

  test "el layout entrega los pasos traducidos al controlador tour" do
    get root_path

    assert_select "body[data-controller~=tour]"
    config = tour_config
    assert_equal I18n.t("tutorial.steps").size, config["steps"].size
    assert_equal I18n.t("tutorial.steps").first[:title], config["steps"].first["title"]
    assert_equal "Siguiente", config["labels"]["next"]
  end

  test "cada paso con target apunta a un elemento que existe en la interfaz" do
    travel_to Date.new(2026, 11, 18) do # dentro de S1 (fixtures): aparece el atajo a la semana
      get plan_weeks_path
    end

    tour_config["steps"].filter_map { |step| step["target"] }.each do |target|
      assert_select "[data-tour=?]", target, { minimum: 1 }, "no existe data-tour=\"#{target}\""
    end
  end

  test "arranca solo en el inicio" do
    get root_path
    assert_select "body[data-tour-autostart-value=true]"

    get plan_weeks_path
    assert_select "body[data-tour-autostart-value=false]"
  end

  test "el menú de usuario permite volver a ver el tutorial" do
    get plan_weeks_path

    assert_select "#user-menu button[data-action~='tour#start']", /Ver tutorial/
  end
end
