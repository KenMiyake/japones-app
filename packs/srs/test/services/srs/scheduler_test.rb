require "test_helper"

module Srs
  class SchedulerTest < ActiveSupport::TestCase
    setup do
      @scheduler = Scheduler.new
      @now = Time.zone.local(2026, 11, 24, 10)
      @card = Card.create!(reviewable: lessons(:l01), card_type: "read", due_at: @now)
    end

    test "preview de una tarjeta nueva: 1 min, 6 min, 10 min y varios días" do
      preview = @scheduler.preview(@card, now: @now)

      assert_equal %w[again hard good easy], preview.keys
      assert_equal @now + 1.minute, preview["again"]
      assert_equal @now + 6.minutes, preview["hard"]
      assert_equal @now + 10.minutes, preview["good"]
      assert_operator preview["easy"], :>=, @now + 1.day
    end

    test "preview no modifica la tarjeta ni guarda repasos" do
      @scheduler.preview(@card, now: @now)

      assert @card.reload.state_new?
      assert_equal 0, @card.reviews.count
    end

    test "Bien en una tarjeta nueva la pasa a aprendizaje por 10 minutos" do
      @scheduler.review!(@card, :good, now: @now)

      @card.reload
      assert @card.state_learning?
      assert_equal @now + 10.minutes, @card.due_at
      assert_equal 1, @card.reps
      assert_equal @now, @card.last_reviewed_at
    end

    test "Fácil en una tarjeta nueva la gradúa directo a repaso" do
      @scheduler.review!(@card, :easy, now: @now)

      assert @card.reload.state_review?
      assert_operator @card.scheduled_days, :>=, 1
    end

    test "cada repaso queda registrado con el estado previo de la tarjeta" do
      @scheduler.review!(@card, :good, now: @now)

      review = @card.reviews.last
      assert review.rated_good?
      assert review.was_new?
      assert_equal @now, review.reviewed_at
      assert_equal 0.0, review.stability
    end

    test "con respuestas Bien los intervalos crecen" do
      intervals = []
      time = @now
      4.times do
        @scheduler.review!(@card, :good, now: time)
        intervals << @card.reload.scheduled_days
        time = @card.due_at
      end

      assert @card.state_review?
      assert_equal intervals.sort, intervals, "los intervalos no deberían bajar: #{intervals.inspect}"
      assert_operator intervals.last, :>, intervals.select(&:positive?).first
    end

    test "Otra vez en una tarjeta en repaso la manda a reaprender y cuenta un olvido" do
      time = @now
      3.times do
        @scheduler.review!(@card, :good, now: time)
        time = @card.reload.due_at
      end
      assert @card.state_review?

      @scheduler.review!(@card, :again, now: time)

      @card.reload
      assert @card.state_relearning?
      assert_equal 1, @card.lapses
      assert_equal time + 10.minutes, @card.due_at
      assert @card.reviews.last.rated_again?
    end

    test "deshacer devuelve la tarjeta al estado anterior y borra el repaso" do
      @scheduler.review!(@card, :good, now: @now)
      before = @card.reload.attributes.slice("state", "due_at", "stability", "difficulty", "reps", "lapses")
      @scheduler.review!(@card, :again, now: @card.due_at)

      @scheduler.undo!(@card)

      @card.reload
      assert_equal 1, @card.reviews.count
      assert_equal before["state"], @card.state
      assert_equal before["reps"], @card.reps
      assert_in_delta before["stability"], @card.stability, 0.0001
      assert_equal @now, @card.last_reviewed_at
    end

    test "deshacer sin repasos no hace nada" do
      assert_nothing_raised { @scheduler.undo!(@card) }
      assert @card.reload.state_new?
    end

    test "una respuesta desconocida lanza un error y no guarda nada" do
      assert_raises(ArgumentError) { @scheduler.review!(@card, :maso, now: @now) }
      assert_equal 0, Review.count
    end

    test "mark_known! gradúa una tarjeta nueva a repaso con la fecha indicada y sin registrar repasos" do
      due = @now + 4.days

      @scheduler.mark_known!(@card, now: @now, due_at: due)

      @card.reload
      assert @card.state_review?
      assert_equal due, @card.due_at
      assert_equal 4, @card.scheduled_days
      assert_operator @card.stability, :>, 1
      assert_equal 0, @card.reps
      assert_equal 0, @card.reviews.count
    end

    test "mark_known! no toca tarjetas ya vistas" do
      @scheduler.review!(@card, :good, now: @now)

      @scheduler.mark_known!(@card, now: @now, due_at: @now + 5.days)

      assert @card.reload.state_learning?
    end

    test "reset! vuelve la tarjeta a nueva" do
      @scheduler.mark_known!(@card, now: @now)

      @scheduler.reset!(@card, now: @now)

      @card.reload
      assert @card.state_new?
      assert_equal 0.0, @card.stability
      assert_nil @card.last_reviewed_at
    end

    test "retrievability es nil en tarjetas nuevas y baja con el tiempo" do
      assert_nil @scheduler.retrievability(@card, now: @now)

      @scheduler.review!(@card, :easy, now: @now)
      soon = @scheduler.retrievability(@card.reload, now: @now + 1.day)
      later = @scheduler.retrievability(@card, now: @now + 30.days)

      assert_operator soon, :>, later
      assert_operator soon, :<=, 1.0
    end
  end
end
