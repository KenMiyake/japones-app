# Pack `srs`

Motor de **repetición espaciada**: tarjetas, repasos y el algoritmo FSRS. Es genérico: no
depende de ningún dominio. Decisión y alternativas en el
[ADR 0004](../../docs/decisions/0004-repaso-propio-con-fsrs.md).

> Estado: paso R1 (modelos y adaptador). Todavía no hay pantallas ni generación de tarjetas.

## Modelos

| Modelo | Tabla | Qué es |
|---|---|---|
| `Srs::Card` | `srs_cards` | Una tarjeta: algo repasable (`reviewable`, polimórfico) + un tipo (`card_type`, p. ej. `read`), con su estado FSRS. Una sola por repasable y tipo (`Srs::Card.for(kanji, :read)`). |
| `Srs::Review` | `srs_reviews` | Un repaso: la respuesta (`again`, `hard`, `good`, `easy`) y el estado de la tarjeta **antes** de responder. |

Estados de una tarjeta (`state`):

```
new ──Bien──▶ learning ──Bien──▶ review ──Otra vez──▶ relearning ──Bien──▶ review
       (pasos de minutos)          (días)              (pasos de minutos)
```

Scopes útiles: `Srs::Card.due(now)` (vistas y vencidas), `Srs::Card.unseen` (nuevas),
`Srs::Card.by_due`, `Srs::Review.since(fecha)`, `Srs::Review.lapses` (los "Otra vez").

## El adaptador: `Srs::Scheduler`

Es el único código que conoce la gema `fsrs_ruby`.

```ruby
scheduler = Srs::Scheduler.new
card = Srs::Card.for(kanji, :read)

scheduler.preview(card)        # => { "again" => 1 min, "hard" => 6 min, "good" => 10 min, "easy" => +8 días }
scheduler.review!(card, :good) # guarda el repaso y actualiza la tarjeta
scheduler.undo!(card)          # deshace el último repaso
scheduler.retrievability(card) # probabilidad de recordarla ahora (0–1)
```

Parámetros por defecto en `Srs::Scheduler::DEFAULTS`: retención 90 %, pasos `1m 10m`,
reaprendizaje `10m`, sin fuzz.

## Probarlo en consola

```sh
docker compose run --rm web bin/rails console
```

```ruby
kanji = KanjiStudy::Kanji.find_by!(character: "場")
card = Srs::Card.for(kanji, :read)
s = Srs::Scheduler.new
s.preview(card)
s.review!(card, :good)
card.reload.state       # => "learning"
card.due_at             # => dentro de 10 minutos
card.reviews.last       # el repaso, con el estado previo
s.undo!(card)           # vuelve a "new"
```

## Tests

`packs/srs/test/`: el modelo y el adaptador. Usan una `Lesson` de `core` como "repasable"
para no depender de ningún dominio.
