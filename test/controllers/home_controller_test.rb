require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "la raíz muestra la página de inicio en español" do
    get root_path

    assert_response :success
    assert_select "html[lang=es]"
    assert_select "h1", "Gestor de kanji"
  end
end
