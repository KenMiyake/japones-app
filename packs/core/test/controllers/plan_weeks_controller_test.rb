require "test_helper"

class PlanWeeksControllerTest < ActionDispatch::IntegrationTest
  test "la raíz muestra el plan con todas las semanas en orden" do
    get root_path

    assert_response :success
    assert_select "html[lang=es]"
    assert_select "h1", "Plan de estudio"
    assert_select "ol li", 3
    assert_select "ol li:first-child", /S1/
    assert_select "##{dom_id(plan_weeks(:s4))}", /provisional/
  end

  test "marca la semana actual" do
    travel_to Date.new(2026, 12, 9) do
      get plan_weeks_path
    end

    assert_select "##{dom_id(plan_weeks(:s4))}", /esta semana/
    assert_select "##{dom_id(plan_weeks(:s1))}", text: /esta semana/, count: 0
  end

  test "sin semanas, indica cómo cargarlas" do
    PlanWeek.delete_all

    get root_path

    assert_select "code", "bin/rails db:seed"
  end

  test "la semana se busca por código y muestra sus lecciones" do
    get plan_week_path("S4")

    assert_response :success
    assert_select "h1", "S4"
    assert_select "li##{dom_id(lessons(:l08))}", /L08/
    assert_select "li##{dom_id(lessons(:l09))}", /L09/
    assert_select "li##{dom_id(lessons(:l10))}", count: 0
    assert_select "p", /provisional/
  end

  test "una semana inexistente responde 404" do
    get plan_week_path("S99")

    assert_response :not_found
  end
end
