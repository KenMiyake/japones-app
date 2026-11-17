require "test_helper"

module KanjiStudy
  class PendingKanjisControllerTest < ActionDispatch::IntegrationTest
    test "por defecto muestra la semana actual, con resumen y filas" do
      travel_to Date.new(2026, 12, 15) do
        get pending_kanjis_path
      end

      assert_response :success
      assert_select "turbo-frame#pending_list" do
        assert_select "nav a[aria-current=page]", "S5"
        assert_select "#pending_summary", /1\s+de 1 kanji por completar/
        assert_select "turbo-frame#pending_kanji_#{kanjis(:aida).id}", /間/
        assert_select "turbo-frame#pending_kanji_#{kanjis(:aida).id} a", "Completar"
      end
      assert_select "aside#sidebar nav a[aria-current=page]", /Pendientes/
    end

    test "filtra por lo que falta y por lección" do
      get pending_kanjis_path(week: "all", missing: "lesson")
      assert_select "turbo-frame#pending_kanji_#{kanjis(:hito).id}"
      assert_select "turbo-frame#pending_kanji_#{kanjis(:aida).id}", count: 0

      get pending_kanjis_path(week: "all", lesson: 8)
      assert_select "turbo-frame#pending_kanji_#{kanjis(:aida).id}"
      assert_select "turbo-frame#pending_kanji_#{kanjis(:hito).id}", count: 0
    end

    test "sin pendientes lo celebra" do
      get pending_kanjis_path(week: "S1")

      assert_select "turbo-frame#pending_list", /No queda nada pendiente/
    end

    test "Completar devuelve el formulario dentro del frame de la fila, conservando los filtros" do
      get edit_pending_kanji_path(kanjis(:aida), week: "S5")

      assert_response :success
      assert_select "turbo-frame#pending_kanji_#{kanjis(:aida).id} form[action=?]", pending_kanji_path(kanjis(:aida)) do
        assert_select "input[name='kanji[on_readings_text]']"
        assert_select "input[name='kanji[kun_readings_text]']"
        assert_select "input[type=hidden][name=week][value=S5]"
      end
    end

    test "Cancelar devuelve la fila" do
      get pending_kanji_path(kanjis(:aida), week: "S5")

      assert_select "turbo-frame#pending_kanji_#{kanjis(:aida).id} a", "Completar"
    end

    test "guardar responde con streams que reemplazan la fila y el resumen" do
      kanji = kanjis(:aida)

      patch pending_kanji_path(kanji), as: :turbo_stream, params: {
        week: "S5",
        kanji: { meaning_es: "intervalo", on_readings_text: "カン、ケン", kun_readings_text: "あいだ、ま",
                 lesson_id: lessons(:l10).id, mnemonic: "El sol entre las puertas." }
      }

      assert_response :success
      kanji.reload
      assert kanji.complete?
      assert_equal %w[カン ケン あいだ ま], kanji.readings.map(&:kana)

      assert_select "turbo-stream[action=replace][method=morph][target=?]", "pending_kanji_#{kanji.id}" do
        assert_select "template", /intervalo/
        assert_select "template", /completo/
      end
      assert_select "turbo-stream[target=pending_summary] template", /0\s+de 1 kanji por completar/
    end

    test "con una lectura inválida vuelve el formulario con el error" do
      patch pending_kanji_path(kanjis(:aida)), params: { week: "S5", kanji: { on_readings_text: "かん" } }

      assert_response :unprocessable_content
      assert_select "turbo-frame#pending_kanji_#{kanjis(:aida).id} [role=alert]", /katakana/
      assert_select "input[name='kanji[on_readings_text]'][value=かん]"
      assert_empty kanjis(:aida).readings.reload
    end

    test "la página de la semana enlaza a sus pendientes" do
      get plan_week_path(plan_weeks(:s5))

      assert_select "section#kanji_section a[href=?]", pending_kanjis_path(week: "S5")
    end
  end
end
