require "test_helper"

class TopbarTest < ActionDispatch::IntegrationTest
  test "muestra la ruta de navegación de la página" do
    get plan_week_path(plan_weeks(:s4))

    assert_select "header nav[aria-label=Ruta]" do
      assert_select "a[href=?]", plan_weeks_path, "Plan de estudio"
      assert_select "li[aria-current=page]", "S4"
    end
  end

  test "el atajo lleva a la semana actual" do
    travel_to Date.new(2026, 12, 9) do
      get root_path
    end

    assert_select "header a[href=?][title='Semana actual']", plan_week_path(plan_weeks(:s4)), /S4/
  end

  test "sin semana actual no hay atajo" do
    travel_to Date.new(2026, 1, 1) do
      get root_path
    end

    assert_select "header a[title='Semana actual']", count: 0
  end

  test "el menú de usuario está cerrado y sus opciones aún no están disponibles" do
    get root_path

    assert_select "[data-controller=dropdown]:not([data-open])"
    assert_select "button[aria-haspopup=menu][aria-expanded=false]"
    assert_select "#user-menu [role=menuitem][aria-disabled=true]", 3
    assert_select "#user-menu", /Cerrar sesión/
  end
end
