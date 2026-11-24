# Pack `kanji_study`

Todo lo de kanji: el kanji y sus lecturas, palabras de ejemplo, piezas, grupos para
distinguir y kanji sabidos. Depende de [`core`](../core/README.md) (semanas y lecciones).

Namespace: `KanjiStudy` (no `Kanji`, para evitar `Kanji::Kanji`). Los modelos usan nombres
relativos (`KanjiStudy.use_relative_model_naming?`), así que los parámetros son
`params[:kanji]`, las rutas `kanji_path` y los `dom_id` `kanji_1`. Las traducciones viven
en [`config/locales/es.yml`](config/locales/es.yml), bajo `kanji_study/…`.

## Modelos

```
Kanji ──< KanjiReading
  │ └──< KanjiComponent >── Component
  │ └──< WordKanji >─────── Word
  │ └──< ConfusableMember >─ ConfusableGroup
  └── KnownKanji (0 o 1)

Kanji, ConfusableGroup → PlanWeek (core, opcional)
Kanji, Word            → Lesson (core, opcional)
```

| Modelo | Reglas principales |
|---|---|
| `Kanji` | Un solo carácter Han, único. Semana y lección opcionales; si la lección queda fuera del rango de la semana, solo se avisa (`lesson_outside_plan_week?`). `missing_fields` dice qué falta (significado, lecturas, mnemotecnia, lección). URL: `/kanjis/食`. Scopes `incomplete` y `missing(:campo)`. Lecturas como texto con `on_readings_text` / `kun_readings_text` (conserva las existentes y su marca de Minna). |
| `KanjiReading` | `kind` on/kun. On en katakana, kun en hiragana; el okurigana va aparte y solo en kun. `taught`: si la enseña Minna. Se editan anidadas en el formulario del kanji. |
| `Word` | Texto + lectura (solo kana), única por combinación (今日 きょう / こんにち). Al guardarse se enlaza con los kanji registrados que contiene; `unregistered_kanji` lista los que faltan. Crear o renombrar un kanji vuelve a enlazar las palabras afectadas. |
| `Component` | Pieza: carácter (亻), nombre propio ("techo") o ambos; los dos únicos. En el kanji se asignan con `component_tokens` (texto); las que no existen se crean al guardar (`created_components`). |
| `ConfusableGroup` | 2 o más kanji que se confunden, escritos como `"待/持/特"` en `characters`. Los kanji que no existen se crean como kanji de referencia (`created_kanjis`). `practice_mode`: `card` (tarjeta), `paper` (papel) o `pending` (por confirmar). |
| `KnownKanji` | Marca de "ya lo sé", una por kanji, con la fecha (`marked_on`). Es progreso, no contenido. |

Borrados: al eliminar un kanji se eliminan sus lecturas, enlaces, membresías y marca.
Al eliminar una pieza, una palabra o un grupo, los kanji no se tocan.

## Rutas y pantallas

| Sidebar | Rutas | Qué hace |
|---|---|---|
| 未完 Pendientes | `resources :pending_kanjis, path: "pending", only: %i[index show edit update]` | Kanji incompletos con filtros (semana, por defecto la actual; lección; lo que falta) y edición en la misma fila. Las lecturas se escriben como texto: on `ショク、ジキ`, kun `た.べる、く.う` |
| 漢字 Kanji | `resources :kanjis` | Listado por semana con filtro (Turbo Frame), ficha (lecturas, piezas, palabras, grupos, estado de sabido) y formulario con lecturas anidadas y piezas como chips |
| 言葉 Palabras | `resources :words, except: :show` | Listado con búsqueda mientras se escribe y formulario. Desde la ficha de un kanji se puede crear una palabra que vuelve a esa ficha (`return_to_kanji`) |
| 部品 Piezas | `resources :components, except: :show` | Tarjetas de piezas con los kanji que las usan |
| 区別 Distinguir | `resources :confusable_groups, except: :show` y `PATCH /confusable_groups/:id/practice_mode` | Grupos por semana con el control tarjeta / papel / por confirmar |
| 既知 Sabidos | `GET /known_kanjis`, `POST/DELETE /kanjis/:kanji_id/known_mark` y `POST/DELETE /plan_weeks/:code/known_marks` | Cuadrícula para marcar kanji sabidos, uno a uno o por semana |

## Hotwire en este pack

| Dónde | Técnica |
|---|---|
| Pendientes: filtros y lista | Turbo Frame `pending_list` (los filtros conservan los demás con `PendingQuery#to_params`) |
| Pendientes: completar en la fila | Turbo Frame por fila (`edit` devuelve el formulario en el mismo frame) + Turbo Streams con morph al guardar (`pending_kanjis/update.turbo_stream.erb`) |
| Filtro de semana en Kanji | Turbo Frame `kanji_list` + `data-turbo-action="advance"` (actualiza la URL) |
| Búsqueda de palabras | Turbo Frame `words_list` + controlador `search` (debounce de 250 ms) |
| Lecturas en el formulario del kanji | Controlador `nested-form` (`<template>` + `_destroy`) |
| Piezas en el formulario del kanji | Controlador `tokens` (chips con inputs ocultos) |
| Marcar sabidos | Turbo Streams `replace` con `method: :morph` (`toggle.turbo_stream.erb`, `week.turbo_stream.erb`) |
| Modo de práctica de un grupo | Turbo Stream `replace` con morph (`confusable_practice_modes/update.turbo_stream.erb`) |

Los controladores de Stimulus viven en `app/javascript/controllers/` (se comparten entre packs).

## Tarjetas de repaso

`kanji_study` depende del pack [`srs`](../srs/README.md) y le da sus tarjetas.
[`KanjiStudy::CardSync`](app/services/kanji_study/card_sync.rb) las crea y las mantiene:

| Qué | Tarjetas | Orden de entrada (`new_rank`) |
|---|---|---|
| Kanji del plan | **Leer** (`read`) y **Escribir** (`write`) | Semana, posición del kanji, Leer antes que Escribir (S1 · 1 → `10010`, `10011`) |
| Kanji de referencia (sin semana) | Ninguna | — |
| Grupo para distinguir en modo *tarjeta* | **Distinguir** (`distinguish`) | Después de los kanji de su semana |

Cuándo se sincronizan (callbacks):

- **Kanji:** al crearse en una semana o al cambiar de semana o de posición. Si sale del plan,
  se borran sus tarjetas nunca repasadas (las que tienen historial se conservan).
- **Sabidos:** al marcar un kanji, sus tarjetas nuevas pasan a *en repaso* con
  `Srs::Scheduler#mark_known!`, repartidas en los próximos 7 días (sin registrar repasos).
  Al desmarcarlo, si nunca se repasaron de verdad, vuelven a ser nuevas.
- **Grupos:** al cambiar el modo de práctica o la semana. Fuera de *tarjeta*, se borra su
  tarjeta Distinguir si nunca se repasó.
- **Todo:** `CardSync.sync_all`, que corre al final de `bin/rails db:seed` (idempotente).

En la ficha del kanji, la sección **Repaso** muestra cada tarjeta (estado y próximo repaso)
y el botón **Olvidado** (`POST /kanjis/:kanji_id/cards/:card_type/forgot`), que equivale a
responder *Otra vez*: la tarjeta vuelve hoy, en reaprendizaje.

## Lo que aporta a otros packs

Registra dos secciones en la página de cada semana (`config/initializers/plan_week_sections.rb`):

- `:kanji` (posición 10): los kanji de la semana y cuántos están completos.
- `:confusable_groups` (posición 20): los grupos para distinguir de la semana.

## Datos iniciales

| Seeder | Fuente | Qué crea |
|---|---|---|
| `PlanKanjiSeeder` | `db/seeds/plan.csv` (columna `kanji`) | Los 196 kanji del plan, en su semana y orden |
| `ConfusableGroupSeeder` | `db/seeds/confusable_groups.csv` | Los 22 grupos y los 8 kanji de referencia (人 日 目 干 会 小 大 水) |

Los dos son idempotentes y no sobrescriben lo editado. Corren con `bin/rails db:seed`,
después de `PlanSeeder` (core). Al final, `CardSync.sync_all` crea las tarjetas de repaso
(196 kanji × 2 + los grupos en modo tarjeta).

## Tests

`packs/kanji_study/test/`: modelos, seeders y controladores, con fixtures propios en
`test/fixtures/` (cada uno declara su `model_class`, porque los modelos tienen namespace).
