# Pack `core`

Lo que comparten todos los dominios: las **lecciones** de *Minna no Nihongo I* y las
**semanas del plan** de estudio. No depende de ningún otro pack (ver
[ADR 0001](../../docs/decisions/0001-packs-por-dominio.md)).

## Modelos

| Modelo | Tabla | Qué es |
|---|---|---|
| `Lesson` | `lessons` | Lección del libro (L01–L25). Es solo una referencia: el camino lo marcan las semanas. |
| `PlanWeek` | `plan_weeks` | Semana del plan (S1–S8): fecha de inicio, rango de lecciones y si es provisional. |

Reglas:

- `Lesson#number` es entero positivo y único. El título es opcional.
- `PlanWeek#code` tiene la forma `S<n>` y es único; `position` también es única.
- `last_lesson >= first_lesson` (validado en el modelo y con un check en la base de datos).
- Los rangos de lecciones pueden solaparse: L09 está en S4 y en S5.
- La semana va de lunes a domingo (`ends_on = starts_on + 6`). `PlanWeek.current` es la
  semana que contiene hoy, con la zona horaria de la app (Santiago).
- `PlanWeek#to_param` es el código, así que las URLs son `/plan_weeks/S3`.

## Rutas y pantallas

| Ruta | Pantalla |
|---|---|
| `GET /` y `GET /plan_weeks` | Plan: una tarjeta por semana, con la actual y las provisionales marcadas |
| `GET /plan_weeks/:code` | Semana: secciones de otros packs (kanji, distinguir) y sus lecciones |

## Punto de extensión: `PlanWeekSections`

La página de una semana muestra contenido de otros packs sin que `core` los conozca.
Cada pack registra un partial que recibe el local `plan_week`:

```ruby
# packs/<pack>/config/initializers/plan_week_sections.rb
Rails.application.config.to_prepare do
  PlanWeekSections.register(:mi_seccion, partial: "mi_pack/plan_weeks/section", position: 30)
end
```

- Se ordenan por `position` (menor primero). Registrar dos veces la misma clave la reemplaza.
- Va dentro de `to_prepare` porque en desarrollo el módulo se recarga y el registro se vacía.

Las claves foráneas de otros packs hacia `plan_weeks` y `lessons` usan
`on_delete: :nullify`: `core` puede borrar semanas o lecciones sin saber quién las usa.

## Datos iniciales

[`PlanSeeder`](app/services/plan_seeder.rb) lee `db/seeds/plan.csv` y crea L01–L25 y
S1–S8, desde el lunes 23/11/2026 (semana ISO 48) y en semanas consecutivas. Crea solo lo que falta (no
sobrescribe) y si el CSV trae un error no deja nada a medias.

## Tests

`packs/core/test/`: modelos, seeder, `PlanWeekSections` y controlador. Corren con
`bin/rails test` junto con el resto.
