require "test_helper"

module KanjiStudy
  class ComponentsControllerTest < ActionDispatch::IntegrationTest
    test "el listado muestra cada pieza con sus kanji" do
      get components_path

      assert_response :success
      assert_select "li##{dom_id(components(:yane))}" do
        assert_select "p", /techo/
        assert_select "a[href=?]", kanji_path(kanjis(:taberu)), "食"
      end
      assert_select "li##{dom_id(components(:ninben))}", /Sin kanji/
      assert_select "aside#sidebar nav a[aria-current=page]", /Piezas/
    end

    test "crea, edita y elimina una pieza" do
      post components_path, params: { component: { character: "木", meaning_es: "árbol" } }
      assert_redirected_to components_path
      component = Component.find_by!(character: "木")

      patch component_path(component), params: { component: { name: "árbol" } }
      assert_equal "árbol", component.reload.name

      assert_difference -> { Component.count }, -1 do
        delete component_path(component)
      end
    end

    test "sin carácter ni nombre vuelve al formulario con el error" do
      post components_path, params: { component: { character: "", name: "", meaning_es: "x" } }

      assert_response :unprocessable_content
      assert_select "[role=alert]", /carácter o el nombre/
    end

    test "el formulario del kanji muestra sus piezas como chips y sugiere las existentes" do
      get edit_kanji_path(kanjis(:taberu))

      assert_select "[data-controller=tokens]" do
        assert_select "[data-tokens-target=list] [data-token=?] input[type=hidden][name='kanji[component_tokens][]']", "𠆢"
        assert_select "[data-tokens-target=list] [data-token]", 2
        assert_select "template[data-tokens-target=template]"
        assert_select "datalist#component-options option[value=亻]"
      end
    end

    test "guardar el kanji con piezas nuevas las crea y lo avisa" do
      patch kanji_path(kanjis(:hito)), params: { kanji: { component_tokens: [ "", "亻", "una línea" ] } }

      assert_redirected_to kanji_path(kanjis(:hito))
      follow_redirect!
      assert_select "[role=status]", /Piezas nuevas: una línea/
      assert_select "section", /Piezas/
      assert_select "section a", /亻/
    end

    test "quitar todas las piezas desde el formulario" do
      patch kanji_path(kanjis(:taberu)), params: { kanji: { component_tokens: [ "" ] } }

      assert_empty kanjis(:taberu).reload.components
    end
  end
end
