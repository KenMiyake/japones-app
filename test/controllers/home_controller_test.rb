require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "la raíz saluda con おかえり y Bienvenido" do
    get root_path

    assert_response :success
    assert_select "h1", /おかえり/
    assert_select "svg.okaeri text.okaeri-char", 4
    assert_select "p", "Bienvenido"
  end

  test "durante el plan muestra el día de la semana actual y lleva a ella" do
    travel_to Date.new(2026, 12, 9) do
      get root_path
    end

    assert_select "p", /Semana\s+S4\s+· día 3 de 7/
    assert_select "a[href=?]", plan_week_path(plan_weeks(:s4)), "Continuar con S4"
  end

  test "antes del plan indica cuándo empieza" do
    travel_to Date.new(2026, 11, 1) do
      get root_path
    end

    assert_select "p", /El plan empieza el 16 de noviembre de 2026/
  end

  test "ninguna sección del sidebar aparece activa en el inicio" do
    get root_path

    assert_select "aside#sidebar nav a[aria-current]", count: 0
  end
end
