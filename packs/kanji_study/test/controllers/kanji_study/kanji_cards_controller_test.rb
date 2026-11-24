require "test_helper"

module KanjiStudy
  class KanjiCardsControllerTest < ActionDispatch::IntegrationTest
    setup do
      KnownKanji.mark(kanjis(:aida)) # sus tarjetas quedan "en repaso"
      @card = kanjis(:aida).srs_cards.find_by!(card_type: "read")
    end

    test "la ficha muestra el estado de cada tarjeta y el botón Olvidado" do
      get kanji_path(kanjis(:aida))

      assert_select "section#kanji_cards" do
        assert_select "li##{dom_id(@card)}", /Leer.*en repaso/m
        assert_select "li##{dom_id(@card)} button", "Olvidado"
      end
    end

    test "Olvidado manda la tarjeta a reaprender hoy" do
      post forgot_kanji_card_path(kanjis(:aida), "read")

      assert_redirected_to kanji_path(kanjis(:aida))
      @card.reload
      assert @card.state_relearning?
      assert_operator @card.due_at, :<=, 15.minutes.from_now
      assert @card.reviews.last.rated_again?
      follow_redirect!
      assert_select "[role=status]", /間 \(Leer\) marcado como olvidado: vuelve hoy/
    end

    test "Olvidado en una tarjeta nueva no hace nada y lo avisa" do
      kanji = Kanji.create!(character: "水", plan_week: plan_weeks(:s4), position: 3)

      post forgot_kanji_card_path(kanji, "read")

      assert kanji.srs_cards.find_by!(card_type: "read").state_new?
      follow_redirect!
      assert_select "[role=status]", /todavía es nueva/
    end
  end
end
