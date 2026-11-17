require "test_helper"

module KanjiStudy
  class KnownKanjisControllerTest < ActionDispatch::IntegrationTest
    test "la cuadrícula muestra todos los kanji por semana y el progreso" do
      get known_kanjis_path

      assert_response :success
      assert_select "#known_counter", /1\s+de 3 kanji sabidos/
      assert_select "section#known_week_S1 button[aria-pressed=false]", /食/
      assert_select "section#known_week_none button[aria-pressed=true]", /人/
      assert_select "section#known_week_none button", text: "Marcar todos", count: 0
      assert_select "aside#sidebar nav a[aria-current=page]", /Sabidos/
    end

    test "marcar un kanji responde con streams que actualizan ficha y contadores" do
      post kanji_known_mark_path(kanjis(:taberu)), as: :turbo_stream

      assert_response :success
      assert_equal "text/vnd.turbo-stream.html", response.media_type
      assert kanjis(:taberu).reload.known?

      assert_select "turbo-stream[action=replace][method=morph][target=?]", "known_kanji_#{kanjis(:taberu).id}" do
        assert_select "template button[aria-pressed=true]", /済/
      end
      assert_select "turbo-stream[target=known_week_count_S1] template", /1\s+\/ 1/
      assert_select "turbo-stream[target=known_counter] template", /2\s+de 3/
    end

    test "desmarcar un kanji" do
      delete kanji_known_mark_path(kanjis(:hito)), as: :turbo_stream

      assert_not kanjis(:hito).reload.known?
      assert_select "turbo-stream[target=?] template button[aria-pressed=false]", "known_kanji_#{kanjis(:hito).id}"
      assert_select "turbo-stream[target=known_week_count_none]"
    end

    test "sin Turbo, vuelve a la cuadrícula" do
      post kanji_known_mark_path(kanjis(:taberu))

      assert_redirected_to known_kanjis_path
      assert kanjis(:taberu).reload.known?
    end

    test "marcar y desmarcar una semana completa" do
      post plan_week_known_marks_path(plan_weeks(:s5)), as: :turbo_stream

      assert kanjis(:aida).reload.known?
      assert_select "turbo-stream[target=known_week_S5] template section button[aria-pressed=true]", /間/
      assert_select "turbo-stream[target=known_counter]"

      delete plan_week_known_marks_path(plan_weeks(:s5)), as: :turbo_stream

      assert_not kanjis(:aida).reload.known?
      assert kanjis(:hito).reload.known?, "no toca kanji de otras semanas"
    end

    test "la ficha del kanji indica desde cuándo se sabe" do
      get kanji_path(kanjis(:hito))

      assert_select "span", /sabido desde el 16 nov/
    end
  end
end
