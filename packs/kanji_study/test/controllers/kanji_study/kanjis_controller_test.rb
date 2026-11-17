require "test_helper"

module KanjiStudy
  class KanjisControllerTest < ActionDispatch::IntegrationTest
    test "el listado agrupa por semana y deja al final los sin semana" do
      get kanjis_path

      assert_response :success
      assert_select "turbo-frame#kanji_list" do
        assert_select "section", 3
        assert_select "section:first-of-type h2", /S1/
        assert_select "section:last-of-type h2", /Sin semana/
        assert_select "a##{dom_id(kanjis(:taberu))}", /食/
      end
    end

    test "filtra por semana y por kanji sin semana" do
      get kanjis_path(week: "S5")
      assert_select "a##{dom_id(kanjis(:aida))}"
      assert_select "a##{dom_id(kanjis(:taberu))}", count: 0
      assert_select "nav a[aria-current=page]", "S5"

      get kanjis_path(week: "none")
      assert_select "a##{dom_id(kanjis(:hito))}"
      assert_select "a##{dom_id(kanjis(:aida))}", count: 0
    end

    test "una semana inexistente en el filtro responde 404" do
      get kanjis_path(week: "S99")

      assert_response :not_found
    end

    test "la ficha se encuentra por el carácter y muestra lecturas y avisos" do
      get kanji_path("間")
      assert_response :success
      assert_select "h1", /Sin significado/
      assert_select "dd", /fuera del rango de S5/

      get kanji_path(kanjis(:taberu))
      assert_select "h1", "comer"
      assert_select "dd span[title='La enseña Minna']", /ショク/
      assert_select "dd", /た·べる/
    end

    test "el formulario nuevo trae una fila on y una kun, y la semana pedida" do
      get new_kanji_path(week: "S5")

      assert_response :success
      assert_select "select[name='kanji[plan_week_id]'] option[selected][value=?]", plan_weeks(:s5).id.to_s
      assert_select "[data-nested-form-target=list] [data-nested-form-row]", 2
      assert_select "template[data-nested-form-target=template]"
      # Ojo con YAML: un valor On sin comillas se lee como true.
      assert_select "[data-nested-form-row] select option[value=on]", "On"
      assert_select "[data-nested-form-row] select option[value=kun]", "Kun"
    end

    test "al editar un kanji sin lecturas ofrece una fila on y una kun; con lecturas, solo las suyas" do
      get edit_kanji_path(kanjis(:hito))
      assert_select "[data-nested-form-target=list] [data-nested-form-row]", 2

      get edit_kanji_path(kanjis(:taberu))
      assert_select "[data-nested-form-target=list] [data-nested-form-row][data-new-record=false]", 2
      assert_select "[data-nested-form-target=list] [data-nested-form-row][data-new-record=true]", 0
    end

    test "crea un kanji con sus lecturas" do
      assert_difference -> { Kanji.count } => 1, -> { KanjiReading.count } => 2 do
        post kanjis_path, params: { kanji: {
          character: "水", meaning_es: "agua", plan_week_id: plan_weeks(:s1).id,
          readings_attributes: {
            "0" => { kind: "on", kana: "スイ", taught: "1" },
            "1" => { kind: "kun", kana: "みず", taught: "0" },
            "1700000000000" => { kind: "kun", kana: "", okurigana: "" }
          }
        } }
      end

      kanji = Kanji.find_by!(character: "水")
      assert_redirected_to kanji_path(kanji)
      assert_equal %w[スイ みず], kanji.readings.map(&:kana)
      assert kanji.readings.first.taught?
      follow_redirect!
      assert_select "[role=status]", /Kanji 水 creado/
    end

    test "con datos inválidos vuelve a mostrar el formulario con los errores" do
      assert_no_difference -> { Kanji.count } do
        post kanjis_path, params: { kanji: {
          character: "あ",
          readings_attributes: { "0" => { kind: "on", kana: "すい" } }
        } }
      end

      assert_response :unprocessable_content
      assert_select "[role=alert]", /debe ser un solo kanji/
      assert_select "[data-nested-form-row] p", /katakana/
    end

    test "actualiza datos, agrega y elimina lecturas" do
      kanji = kanjis(:taberu)

      patch kanji_path(kanji), params: { kanji: {
        meaning_es: "comer; comida",
        readings_attributes: {
          "0" => { id: kanji_readings(:taberu_shoku).id, kind: "on", kana: "ショク" },
          "1" => { id: kanji_readings(:taberu_ta).id, _destroy: "1" },
          "1700000000000" => { kind: "kun", kana: "く", okurigana: "う" }
        }
      } }

      assert_redirected_to kanji_path(kanji)
      kanji.reload
      assert_equal "comer; comida", kanji.meaning_es
      assert_equal %w[ショク く], kanji.readings.map(&:kana)
    end

    test "si se cambia el carácter, redirige a la nueva URL" do
      patch kanji_path(kanjis(:hito)), params: { kanji: { character: "入" } }

      assert_redirected_to kanji_path("入")
    end

    test "elimina el kanji" do
      assert_difference -> { Kanji.count }, -1 do
        delete kanji_path(kanjis(:taberu))
      end

      assert_redirected_to kanjis_path
      assert_response :see_other
    end

    test "la página de la semana muestra sus kanji (sección registrada por el pack)" do
      get plan_week_path(plan_weeks(:s1))

      assert_select "section#kanji_section" do
        assert_select "a##{dom_id(kanjis(:taberu))}", /食/
        assert_select "a[href=?]", new_kanji_path(week: "S1")
      end
      assert_select "section#kanji_section", /1 · 1 completos/
    end

    test "el sidebar marca Kanji como sección activa" do
      get kanji_path(kanjis(:taberu))

      assert_select "aside#sidebar nav a[aria-current=page]", /Kanji/
    end
  end
end
