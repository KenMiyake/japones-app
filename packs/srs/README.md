# Pack `srs`

Motor de **repetición espaciada**: tarjetas, repasos, la cola diaria y el algoritmo FSRS.
Es genérico: no depende de ningún dominio. Decisión y alternativas en el
[ADR 0004](../../docs/decisions/0004-repaso-propio-con-fsrs.md).

> Estado: pasos R1 (modelos y adaptador) y R2 (cola diaria; las tarjetas de kanji las crea
> `kanji_study`). La pantalla de repaso llega en R3.

## Modelos

| Modelo | Tabla | Qué es |
|---|---|---|
| `Srs::Card` | `srs_cards` | Una tarjeta: algo repasable (`reviewable`, polimórfico) + un tipo (`card_type`, p. ej. `read`), con su estado FSRS y su `new_rank` (orden de entrada si es nueva). Una sola por repasable y tipo (`Srs::Card.for(kanji, :read)`). |
| `Srs::Review` | `srs_reviews` | Un repaso: la respuesta (`again`, `hard`, `good`, `easy`) y el estado de la tarjeta **antes** de responder. |

Estados de una tarjeta (`state`):

```
new ──Bien──▶ learning ──Bien──▶ review ──Otra vez──▶ relearning ──Bien──▶ review
       (pasos de minutos)          (días)              (pasos de minutos)
```

Scopes útiles: `Srs::Card.due(now)` (vistas y vencidas), `Srs::Card.unseen` (nuevas),
`Srs::Card.by_due`, `Srs::Card.by_new_rank`, `Srs::Card.of_types(:read)`,
`Srs::Review.since(fecha)`, `Srs::Review.lapses` (los "Otra vez").

## El adaptador: `Srs::Scheduler`

Es el único código que conoce la gema `fsrs_ruby`.

```ruby
scheduler = Srs::Scheduler.new
card = Srs::Card.for(kanji, :read)

scheduler.preview(card)        # => { "again" => 1 min, "hard" => 6 min, "good" => 10 min, "easy" => +8 días }
scheduler.review!(card, :good) # guarda el repaso y actualiza la tarjeta
scheduler.undo!(card)          # deshace el último repaso
scheduler.retrievability(card) # probabilidad de recordarla ahora (0–1)

scheduler.mark_known!(card, due_at: 3.days.from_now) # nueva → en repaso, sin registrar repaso
scheduler.reset!(card)                               # vuelve a nueva
```

- **`mark_known!`** sirve para lo que ya se sabe (los kanji de "Sabidos"): toma la
  estabilidad y la dificultad de una respuesta "Fácil", pero con la fecha indicada, y **no**
  registra un repaso, porque no lo hubo. Solo afecta tarjetas nuevas.
- Parámetros por defecto en `Srs::Scheduler::DEFAULTS`: retención 90 %, pasos `1m 10m`,
  reaprendizaje `10m`, sin fuzz.

## La cola de hoy: `Srs::ReviewQueue`

```ruby
queue = Srs::ReviewQueue.new                 # new_per_day: 5 (Srs::ReviewQueue::NEW_PER_DAY)
queue.due_cards   # vencidas, la más atrasada primero
queue.new_cards   # nuevas de hoy, en orden de new_rank
queue.next_card   # la próxima: primero las vencidas, después las nuevas
queue.counts      # => { due: 0, new: 10 }
```

Reglas:

- **El cupo de nuevas cuenta repasables, no tarjetas.** Con 5, entran 5 kanji por día, cada
  uno con todas sus tarjetas (Leer y Escribir): son los bloques diarios del plan.
- **Un repasable empezado hoy no gasta otro cupo**: si ya viste la tarjeta Leer de 場, su
  tarjeta Escribir sigue en la cola y los cupos restantes se llenan con los siguientes.
- **El orden lo fija cada dominio** con `new_rank` (en kanji, el del plan). Las tarjetas sin
  `new_rank` nunca entran como nuevas.
- **El día** va de medianoche a medianoche en la zona horaria de la app (Santiago).
- `card_types:` filtra por tipo (p. ej. solo `:read`).

## Probarlo en consola

```sh
docker compose run --rm web bin/rails console
```

```ruby
q = Srs::ReviewQueue.new
q.counts                                         # => {due: 0, new: 10}
q.new_cards.map { |c| [c.reviewable.character, c.card_type] }
# => [["英", "read"], ["英", "write"], ["新", "read"], …]

card = q.next_card
s = Srs::Scheduler.new
s.preview(card)
s.review!(card, :good)
card.reload.state       # => "learning"
card.reviews.last       # el repaso, con el estado previo
s.undo!(card)           # vuelve a "new"
```

## Tests

`packs/srs/test/`: modelo, adaptador y cola. Usan `Lesson` de `core` como "repasable" para no
depender de ningún dominio.
