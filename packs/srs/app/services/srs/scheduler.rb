module Srs
  # Adaptador del algoritmo FSRS: el ÚNICO lugar de la app que conoce la gema fsrs_ruby.
  # Si algún día se cambia de gema (o se escribe el algoritmo a mano), solo cambia este
  # archivo. Ver docs/decisions/0004.
  #
  #   scheduler = Srs::Scheduler.new
  #   scheduler.preview(card)          # => { "again" => <fecha>, "hard" => …, "good" => …, "easy" => … }
  #   scheduler.review!(card, :good)   # guarda el repaso y actualiza la tarjeta
  #   scheduler.undo!(card)            # deshace el último repaso
  class Scheduler
    RATINGS = { "again" => 1, "hard" => 2, "good" => 3, "easy" => 4 }.freeze
    STATES = %w[new learning review relearning].freeze # índice = valor numérico de FSRS

    # Retención deseada del 90 % y los pasos de aprendizaje de Anki. Sin "fuzz" (variación
    # aleatoria de intervalos) para que las fechas sean predecibles.
    DEFAULTS = {
      request_retention: 0.9,
      maximum_interval: 36_500,
      learning_steps: %w[1m 10m],
      relearning_steps: %w[10m],
      enable_fuzz: false
    }.freeze

    def initialize(**params)
      @fsrs = FsrsRuby.new(DEFAULTS.merge(params))
    end

    # Cuándo volvería la tarjeta con cada respuesta (para mostrarlo en los botones).
    def preview(card, now: Time.current)
      @fsrs.repeat(to_fsrs(card), now).to_h do |grade, item|
        [ RATINGS.key(grade), item.card.due ]
      end
    end

    # Registra la respuesta: guarda el repaso (con el estado previo) y actualiza la tarjeta.
    def review!(card, rating, now: Time.current)
      rating = rating.to_s
      grade = RATINGS.fetch(rating) { raise ArgumentError, "respuesta desconocida: #{rating.inspect}" }
      result = @fsrs.next(to_fsrs(card), now, grade)

      Card.transaction do
        card.reviews.create!(rating:, reviewed_at: now, **log_attributes(result.log))
        card.update!(card_attributes(result.card))
      end
      card
    end

    # Deshace el último repaso: la tarjeta vuelve al estado en que estaba antes.
    def undo!(card)
      review = card.reviews.last or return card
      previous = @fsrs.rollback(to_fsrs(card), to_fsrs_log(review))

      Card.transaction do
        review.destroy!
        card.update!(card_attributes(previous).merge(last_reviewed_at: card.reviews.reload.last&.reviewed_at))
      end
      card
    end

    # Gradúa directo a repaso una tarjeta nueva de algo que ya se sabe (p. ej. un kanji marcado
    # como sabido): toma la estabilidad y la dificultad de una respuesta "Fácil", pero con la
    # fecha que se le indique (para repartir los repasos). No registra un repaso: no lo hubo.
    def mark_known!(card, now: Time.current, due_at: now + 1.day)
      return card unless card.state_new?

      easy = @fsrs.repeat(to_fsrs(card), now)[RATINGS.fetch("easy")].card
      card.update!(
        card_attributes(easy).merge(
          due_at:, last_reviewed_at: now, reps: 0,
          scheduled_days: [ (due_at.to_date - now.to_date).to_i, 1 ].max
        )
      )
      card
    end

    # Vuelve la tarjeta a "nueva", como si nunca se hubiera visto. No borra repasos: quien la
    # llama decide si corresponde (p. ej. solo si la tarjeta no tiene repasos).
    def reset!(card, now: Time.current)
      card.update!(
        state: "new", due_at: now, stability: 0.0, difficulty: 0.0, elapsed_days: 0,
        scheduled_days: 0, learning_steps: 0, reps: 0, lapses: 0, last_reviewed_at: nil
      )
      card
    end

    # Probabilidad (0–1) de recordar la tarjeta ahora. nil si nunca se repasó.
    def retrievability(card, now: Time.current)
      return if card.state_new?

      @fsrs.get_retrievability(to_fsrs(card), now, format: false)
    end

    private

    def to_fsrs(card)
      FsrsRuby::Card.new(
        due: card.due_at, stability: card.stability, difficulty: card.difficulty,
        elapsed_days: card.elapsed_days, scheduled_days: card.scheduled_days,
        learning_steps: card.learning_steps, reps: card.reps, lapses: card.lapses,
        state: STATES.index(card.state), last_review: card.last_reviewed_at
      )
    end

    def to_fsrs_log(review)
      FsrsRuby::ReviewLog.new(
        rating: RATINGS.fetch(review.rating), state: STATES.index(review.state), due: review.due_at,
        stability: review.stability, difficulty: review.difficulty, elapsed_days: review.elapsed_days,
        last_elapsed_days: review.last_elapsed_days, scheduled_days: review.scheduled_days,
        learning_steps: review.learning_steps, review: review.reviewed_at
      )
    end

    def card_attributes(fsrs_card)
      {
        state: STATES.fetch(fsrs_card.state), due_at: fsrs_card.due,
        stability: fsrs_card.stability, difficulty: fsrs_card.difficulty,
        elapsed_days: fsrs_card.elapsed_days, scheduled_days: fsrs_card.scheduled_days,
        learning_steps: fsrs_card.learning_steps, reps: fsrs_card.reps, lapses: fsrs_card.lapses,
        last_reviewed_at: fsrs_card.last_review
      }
    end

    def log_attributes(log)
      {
        state: STATES.fetch(log.state), due_at: log.due, stability: log.stability, difficulty: log.difficulty,
        elapsed_days: log.elapsed_days, last_elapsed_days: log.last_elapsed_days,
        scheduled_days: log.scheduled_days, learning_steps: log.learning_steps
      }
    end
  end
end
