require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "date_range en el mismo mes muestra el mes una vez" do
    assert_equal "16–22 nov", date_range(Date.new(2026, 11, 16), Date.new(2026, 11, 22))
  end

  test "date_range entre meses muestra ambos meses" do
    assert_equal "30 nov – 6 dic", date_range(Date.new(2026, 11, 30), Date.new(2026, 12, 6))
  end

  test "date_range entre años muestra los años" do
    assert_equal "28 dic 2026 – 3 ene 2027", date_range(Date.new(2026, 12, 28), Date.new(2027, 1, 3))
  end

  test "badge aplica el tono pedido" do
    html = badge("provisional", tone: :warning)

    assert_includes html, "provisional"
    assert_includes html, "bg-amber-50"
  end
end
