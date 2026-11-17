require "test_helper"

class SidebarTest < ActionDispatch::IntegrationTest
  test "el sidebar marca la sección actual" do
    get plan_weeks_path

    assert_select "aside#sidebar nav a[aria-current=page]", /Plan/
  end

  test "la sección sigue activa dentro de una semana" do
    get plan_week_path(plan_weeks(:s1))

    assert_select "aside#sidebar nav a[aria-current=page]", /Plan/
  end

  test "todas las secciones del sidebar son enlaces" do
    get root_path

    assert_select "aside#sidebar nav a", 6
    assert_select "aside#sidebar nav span[aria-disabled=true]", count: 0
  end

  test "renderiza el sidebar colapsado según la cookie, sin esperar al JS" do
    get root_path
    assert_select "body[data-collapsed]", count: 0
    assert_select "button[data-sidebar-target=toggle][aria-expanded=true]"

    cookies[:sidebar_collapsed] = "1"
    get root_path
    assert_select "body[data-collapsed]"
    assert_select "button[data-sidebar-target=toggle][aria-expanded=false]"
  end
end
