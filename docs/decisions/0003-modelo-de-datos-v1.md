# 0003. Modelo de datos de la v1

- **Estado:** aceptada
- **Fecha:** 2026-11-16

## Contexto

La v1 gestiona el contenido de kanji por semana del plan (S1–S8) y por lección de
*Minna no Nihongo I*. No hay repaso propio todavía (v2) ni autenticación. No se usa Anki,
así que el modelo es propio y no se ajusta a ningún formato externo.

## Modelo

```
core
  Lesson            number (único, 1–25), title (opcional)
  PlanWeek          code (único: S1…S8), position, starts_on,
                    first_lesson, last_lesson (números), provisional

kanji_study
  Kanji             character (único), plan_week_id (opc.), position, lesson_id (opc.),
                    meaning_es, mnemonic, notes
  KanjiReading      kanji_id, kana, kind (on | kun), okurigana, position, taught
  Word              text, reading, meaning_es, lesson_id (opc.)
  WordKanji         word_id, kanji_id, position
  Component         name, character (opc.), meaning_es
  KanjiComponent    kanji_id, component_id, position
  ConfusableGroup   plan_week_id, hint, practice_mode (card | paper | pending)
  ConfusableMember  confusable_group_id, kanji_id, position
  KnownKanji        kanji_id (único), marked_on
```

## Decisiones y por qué

- **`PlanWeek` es el camino de aprendizaje; `Lesson` es solo una referencia al libro.**
  Un kanji puede no tener lección. Si su lección queda fuera del rango de su semana, la app
  avisa pero no lo impide (L09 aparece en S4 y en S5).
- **Lecturas en una tabla 1‑N (`KanjiReading`), no muchos a muchos.** "コウ" es un valor,
  no una entidad: lo interesante (okurigana, si Minna la enseña, orden) depende del par
  kanji–lectura. Para buscar kanji que comparten lectura basta un índice en `kana`.
- **Palabras con muchos a muchos (`Word` ↔ `Kanji`).** Una palabra sí es una entidad
  (lectura, significado, lección) y la comparten varios kanji: 電車 aparece en 電 y en 車.
  Al guardar una palabra se enlaza sola con los kanji existentes que contiene. Enlazar qué
  lectura usa cada kanji en la palabra queda para después (casos como 大人 = おとな).
- **Grupos para distinguir, no pares.** Hay grupos de 3 (待/持/特, 問/間/聞), así que hay
  tabla de miembros. `practice_mode` es un enum de tres estados (tarjeta, papel, por confirmar).
- **Kanji de referencia** (大, 水, 会, 干, 小, 人, 日, 目) son kanji normales sin semana.
- **Kanji sabidos en su propia tabla.** Saber un kanji es progreso, no contenido. En la v2
  servirá para dar el estado inicial del repaso.
- **Las piezas empiezan vacías.** Se crean al escribir mnemotecnias, con los nombres propios
  del usuario. Importar KRADFILE como sugerencia queda fuera de la v1.
- **Sin `Card` persistida en la v1.** En la v2 aparecerá `StudyItem` (kanji + leer/escribir,
  o grupo + distinguir), que sí se guarda porque lleva el estado del repaso, y `Review`
  (una fila por repaso, con la respuesta) para poder recalcular si cambia el algoritmo.
- **Sin `User` en la v1.** Se agregará con la autenticación.
