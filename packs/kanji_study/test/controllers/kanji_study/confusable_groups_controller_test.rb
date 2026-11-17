require "test_helper"

module KanjiStudy
  class ConfusableGroupsControllerTest < ActionDispatch::IntegrationTest
    test "el listado agrupa por semana y resume por modo de práctica" do
      get confusable_groups_path

      assert_response :success
      assert_select "#confusable_summary", /2\s+grupos/
      assert_select "#confusable_summary", /1\s+tarjeta/
      assert_select "article##{dom_id(confusable_groups(:hito_taberu))}" do
        assert_select "a", /人/
        assert_select "button[aria-pressed=true]", "tarjeta"
      end
      assert_select "aside#sidebar nav a[aria-current=page]", /Distinguir/
    end

    test "crea un grupo y avisa los kanji de referencia creados" do
      assert_difference -> { ConfusableGroup.count } => 1, -> { Kanji.count } => 1 do
        post confusable_groups_path, params: { confusable_group: {
          characters: "入/人", plan_week_id: plan_weeks(:s1).id, practice_mode: "card", hint: "入 entra, 人 camina"
        } }
      end

      assert_redirected_to confusable_groups_path
      follow_redirect!
      assert_select "[role=status]", /Grupo 入\/人 creado. Kanji de referencia creados: 入/
    end

    test "con un solo kanji vuelve al formulario con el error" do
      assert_no_difference -> { ConfusableGroup.count } do
        post confusable_groups_path, params: { confusable_group: { characters: "人" } }
      end

      assert_response :unprocessable_content
      assert_select "[role=alert]", /al menos 2 kanji/
    end

    test "edita los kanji y la pista" do
      group = confusable_groups(:aida_hito)

      patch confusable_group_path(group), params: { confusable_group: { characters: "間/食", hint: "Puerta vs. comida" } }

      assert_redirected_to confusable_groups_path
      assert_equal "間/食", group.reload.label
      assert_equal "Puerta vs. comida", group.hint
    end

    test "cambia el modo de práctica desde la tarjeta con Turbo Stream" do
      group = confusable_groups(:aida_hito)

      patch confusable_group_practice_mode_path(group), params: { practice_mode: "paper" }, as: :turbo_stream

      assert_response :success
      assert group.reload.practice_paper?
      assert_select "turbo-stream[action=replace][method=morph][target=?]", dom_id(group) do
        assert_select "template button[aria-pressed=true]", "papel"
      end
      assert_select "turbo-stream[target=confusable_summary]"
    end

    test "un modo de práctica inválido responde 422 sin cambiar nada" do
      group = confusable_groups(:aida_hito)

      patch confusable_group_practice_mode_path(group), params: { practice_mode: "quizás" }, as: :turbo_stream

      assert_response :unprocessable_content
      assert group.reload.practice_pending?
    end

    test "elimina el grupo sin eliminar sus kanji" do
      assert_difference -> { ConfusableGroup.count } => -1, -> { Kanji.count } => 0 do
        delete confusable_group_path(confusable_groups(:hito_taberu))
      end

      assert_redirected_to confusable_groups_path
    end

    test "la página de la semana muestra sus grupos" do
      get plan_week_path(plan_weeks(:s5))

      assert_select "section#confusable_section", /por confirmar/
      assert_select "section#confusable_section a", /間/
    end

    test "la ficha del kanji muestra con qué se confunde" do
      get kanji_path(kanjis(:hito))

      assert_select "section", /Se confunde con/
      assert_select "section li a", /食/
      assert_select "section li span.text-shu", "人"
    end
  end
end
