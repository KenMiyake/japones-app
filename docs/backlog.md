# Backlog

Trabajo futuro, ordenado por prioridad. Nada de esto está implementado todavía.

## Contexto: integración con la guía de Minna

Hay un segundo repositorio, **Material-Japones**, con una guía de *Minna no Nihongo I* en
Markdown: 25 lecciones (escritas L01–L07 y L13), cada una con 15 secciones fijas. Las que
interesan aquí:

| Sección | Contenido |
|---|---|
| 2 | Gramática, con ejemplos numerados "japonés — español" |
| 4 | Tabla de kanji: kanji, significado, on, kun, compuestos, motivo, prioridad, JLPT |
| 6 | Vocabulario (las palabras marcadas 🔧) |
| 8 | Ejercicios con soluciones |
| 12 | Checklist de la lección |
| 13 | Repaso a +1 día, +1 semana y +1 mes |

Ese repositorio ya genera `kanji/anki/kanji.txt` con 118 kanji (clave, piezas, palabra
ancla, lectura, frase, frase con hueco, traducción, on, kun, lección, pares para
distinguir), y `metodo.md` §5 tiene la lista de pares que se confunden.

Hoy el usuario estudia con una bitácora en ese repositorio y quiere pasarse a esta app en
cuanto tenga pantalla de repaso. A largo plazo, la app tendrá un módulo "Minna no Nihongo"
con las lecciones de la guía, enriquecidas e importadas desde ese repositorio.

**Principio: el contenido vive en Markdown en Material-Japones y la app lo importa. Nada se
escribe dos veces.**

## Antes de empezar cualquier punto

Con Docker encendido (`docker compose up -d`), comprobar lo que quedó sin verificar:

- [ ] El estado real (sabido y tarjetas) de los 18 kanji de S1: 英 新 場 地 階 何 語 聞 車 円 百 千 万 国 入 出 男 売.
- [ ] Si existen las filas de los kanji de L07 (父 母 家 族 花 切 送 貸 借 教 習 紙 物, en S3).
- [ ] Si se corrió `bin/rails db:seed` en la base de desarrollo.
- [ ] Si los tests pasan: `docker compose run --rm web bin/rails test`.

## Resumen

| # | Qué | Prioridad | Estado |
|---|---|---|---|
| 1 | Pantalla de repaso (R3) | Alta: requisito para dejar la bitácora | Por hacer |
| 2 | Importar el contenido de los kanji desde la guía | Alta | **Bloqueado**: falta el contrato del JSON |
| 3 | Grupos para distinguir desde la guía | Media | Por hacer (la importación depende del punto 2) |
| 4 | Desplazar el plan | Media | Por hacer |
| 5 | Vista de "sanguijuelas" | Media | Por hacer |
| 6 | Módulo Minna no Nihongo (fases a–e) | Baja: largo plazo | Por hacer |

---

## 1. Pantalla de repaso (R3)

**Prioridad:** alta. Es el requisito para que el usuario deje la bitácora de Material-Japones.
Es el paso R3 del [ADR 0004](decisions/0004-repaso-propio-con-fsrs.md).

Qué incluye:

- La cola del día: tarjetas vencidas más las nuevas que caben en el cupo
  (`Srs::ReviewQueue`, `NEW_PER_DAY`).
- Por cada tarjeta: mostrar el anverso, revelar la respuesta, valorar con
  *again / hard / good / easy* y deshacer el último repaso (`srs_reviews` ya guarda el
  estado previo; ver `Srs::Scheduler#undo!`).

Criterios de aceptación:

- [ ] Muestra primero las vencidas y después las nuevas del día, en el orden de `Srs::ReviewQueue`.
- [ ] Cada tarjeta se puede revelar, valorar con las cuatro respuestas y deshacer.
- [ ] Al valorar, se guarda el repaso y la tarjeta se reprograma con `Srs::Scheduler#review!`.
- [ ] Funciona bien en el móvil (se puede repasar con el pulgar, sin scroll horizontal).

## 2. Importar el contenido de los kanji desde la guía

**Prioridad:** alta. **Bloqueado** hasta que el contrato del JSON esté definido en
Material-Japones. Ese contrato se define primero allí.

Qué incluye:

- Material-Japones generará un JSON (`scripts/exportar-app.py` → `export/minna.json`) con
  el contrato que acuerden los dos repositorios.
- Una tarea rake (p. ej. `minna:import[ruta]`) rellena `kanjis.meaning_es`,
  `kanji_readings`, `words` / `word_kanjis` y `lesson_id`.
- Campos nuevos para lo que hoy no existe: **clave** (*keyword*) y **frase de ejemplo**
  (frase, frase con hueco y traducción).

Criterios de aceptación:

- [ ] Existe el contrato del JSON, versionado y acordado entre los dos repositorios.
- [ ] La tarea rake importa significado, lecturas, palabras, lección, clave y frase de ejemplo.
- [ ] Es idempotente: reimportar actualiza sin duplicar.
- [ ] No pisa `mnemonic` ni `notes` si el usuario ya los escribió.
- [ ] Tras importar, `/pending?week=S1`, `S2` y `S3` salen vacíos en significado, lecturas y lección.

## 3. Grupos para distinguir desde la guía

**Prioridad:** media. La importación depende del punto 2 (mismo JSON).

Qué incluye:

- Importar los pares de `metodo.md` §5 desde el mismo JSON, en vez de mantener
  `db/seeds/confusable_groups.csv` a mano.
- Pasar 貸/借 de *papel* a *tarjeta*, porque la L07 ya está escrita en la guía.

Criterios de aceptación:

- [ ] Los grupos se crean o actualizan desde el JSON, sin duplicar los que ya existen.
- [ ] `db/seeds/confusable_groups.csv` deja de ser la fuente de los grupos.
- [ ] 貸/借 está en modo *tarjeta* y tiene su tarjeta Distinguir.

## 4. Desplazar el plan

**Prioridad:** media. Hoy `plan_weeks.starts_on` es fijo: lo pone `PlanSeeder`
(`DEFAULT_STARTS_ON`, S1 el 23-11-2026), que no sobrescribe, y no hay forma de moverlo
desde la app.

Qué incluye:

- Una acción "desplazar desde la semana X, N días" que mueve `plan_weeks.starts_on` de esa
  semana y de las siguientes, sin tocar las anteriores.
- Ajustar al calendario real del usuario:
  - S1: del 15-11 al 29-11-2026 (dos semanas).
  - S2: desde el lunes 30-11.
  - S3: desde el lunes 07-12.
  - Luego, de lunes a domingo.

Criterios de aceptación:

- [ ] Desplazar desde la semana X mueve X y las siguientes, y deja igual las anteriores.
- [ ] Las fechas reflejan el calendario real del usuario (S1 empieza el 15-11-2026).
- [ ] `PlanWeek.current(hoy)` coincide con la bitácora del usuario.

## 5. Vista de "sanguijuelas" en lugar de un estado "difícil"

**Prioridad:** media. No se agrega un estado "difícil": las sanguijuelas se calculan a
partir del historial de repaso.

Qué incluye:

- Listar los kanji con `lapses ≥ 2` o con un *again* en los últimos 7 días.
- Mostrar su mnemotecnia y un enlace para reescribirla.

Primeros casos reales, con su nota:

- **地**: 土 a secas, la tierra.
- **場**: tierra con el sol encima (昜), un lugar.
- **階**: la colina 阝 con gradas por las que suben todos (皆), los pisos.

Criterios de aceptación:

- [ ] La vista lista los kanji con `lapses ≥ 2` o con un *again* en los últimos 7 días.
- [ ] Cada uno muestra su mnemotecnia y enlaza a editarla.
- [ ] 場, 地 y 階 tienen cargada la nota de arriba.

## 6. Módulo Minna no Nihongo

**Prioridad:** baja (largo plazo). Va por fases, y cada una se entrega por separado. El
contenido llega importado desde Material-Japones (ver el principio de arriba).

### 6a. Lector de lecciones

- [ ] Mapa de la lección con su estado 🟢 / 🟡 / 🔴.
- [ ] Puntos de gramática de la lección.
- [ ] Checklist de la sección 12, con casillas que se guardan.

### 6b. Tarjetas de gramática y vocabulario

- [ ] Los ejemplos numerados de la sección 2 son tarjetas español → japonés en el mismo FSRS (`Srs::Card`).
- [ ] El vocabulario 🔧 de la sección 6 son tarjetas de lectura.

### 6c. Ejercicios

- [ ] Los ejercicios de la sección 8 muestran la solución solo después de responder.
- [ ] Los fallos alimentan la vista de sanguijuelas (punto 5).

### 6d. Repaso de la lección

- [ ] La sección 13 genera recordatorios a +1 día, +1 semana y +1 mes.

### 6e. Enlaces cruzados

- [ ] Se navega kanji ↔ palabra ↔ frase ↔ punto de gramática. Por ejemplo, desde 場 se
      llega a 売り場 y a la frase de la lección donde aparece.

---

## Descartado

- **Exportar a Anki.** Sigue descartado ([ADR 0004](decisions/0004-repaso-propio-con-fsrs.md)):
  la app reemplaza a Anki. No se reabre.
