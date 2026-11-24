require "test_helper"

module KanjiStudy
  class CardSyncTest < ActiveSupport::TestCase
    setup { @now = Time.zone.local(2026, 11, 24, 10) }

    test "cada kanji del plan tiene tarjetas Leer y Escribir; los de referencia no tienen" do
      CardSync.sync_all(now: @now)

      assert_equal %w[read write], kanjis(:taberu).srs_cards.order(:new_rank).pluck(:card_type)
      assert_equal %w[read write], kanjis(:aida).srs_cards.order(:new_rank).pluck(:card_type)
      assert_empty kanjis(:hito).srs_cards
    end

    test "new_rank sigue el plan: semana, posición y Leer antes que Escribir" do
      CardSync.sync_all(now: @now)

      taberu = kanjis(:taberu).srs_cards.order(:new_rank).pluck(:new_rank) # S1, posición 1
      aida = kanjis(:aida).srs_cards.order(:new_rank).pluck(:new_rank)     # S5, posición 1

      assert_equal [ 10_010, 10_011 ], taberu
      assert_equal [ 50_010, 50_011 ], aida
    end

    test "es idempotente" do
      CardSync.sync_all(now: @now)

      assert_no_difference -> { Srs::Card.count } do
        CardSync.sync_all(now: @now)
      end
    end

    test "los kanji sabidos entran en repaso, repartidos en los próximos días" do
      KnownKanji.mark(kanjis(:aida))

      cards = kanjis(:aida).srs_cards.order(:new_rank)
      assert cards.all?(&:state_review?)
      assert cards.all? { |c| c.due_at > Time.current && c.due_at <= 8.days.from_now }
      assert_empty Srs::Review.where(card: cards)
    end

    test "al desmarcar un sabido nunca repasado, sus tarjetas vuelven a ser nuevas" do
      KnownKanji.mark(kanjis(:aida))

      KnownKanji.unmark(kanjis(:aida))

      assert kanjis(:aida).srs_cards.all?(&:state_new?)
    end

    test "al desmarcar, una tarjeta con repasos reales conserva su estado" do
      KnownKanji.mark(kanjis(:aida))
      card = kanjis(:aida).srs_cards.find_by!(card_type: "read")
      Srs::Scheduler.new.review!(card, :good)

      KnownKanji.unmark(kanjis(:aida))

      assert card.reload.state_review?
    end

    test "un grupo en modo tarjeta tiene tarjeta Distinguir, después de los kanji de su semana" do
      group = confusable_groups(:hito_taberu) # S1, modo tarjeta
      CardSync.sync_all(now: @now)

      card = group.srs_cards.sole
      assert_equal "distinguish", card.card_type
      assert_operator card.new_rank, :>, kanjis(:taberu).srs_cards.maximum(:new_rank)
      assert_empty confusable_groups(:aida_hito).srs_cards, "por confirmar: sin tarjeta"
    end

    test "cambiar el modo de práctica crea o quita la tarjeta Distinguir" do
      group = confusable_groups(:aida_hito)

      group.update!(practice_mode: "card")
      assert_equal 1, group.srs_cards.count

      group.update!(practice_mode: "paper")
      assert_equal 0, group.srs_cards.count
    end

    test "un kanji nuevo en una semana obtiene sus tarjetas al crearse; al sacarlo del plan se quitan las no repasadas" do
      kanji = Kanji.create!(character: "水", plan_week: plan_weeks(:s4), position: 3)
      assert_equal 2, kanji.srs_cards.count

      kanji.update!(plan_week: nil)
      assert_equal 0, kanji.srs_cards.count
    end

    test "al eliminar el kanji se eliminan sus tarjetas" do
      CardSync.sync_all(now: @now)

      assert_difference -> { Srs::Card.count }, -2 do
        kanjis(:aida).destroy
      end
    end
  end
end
