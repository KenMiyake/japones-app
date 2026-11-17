# 0001. Organizar el código en packs por dominio

- **Estado:** aceptada
- **Fecha:** 2026-11-16

## Contexto

La v1 cubre solo kanji, pero la idea es extender la app a otros dominios del japonés
(gramática, vocabulario, etc.) sin tener que reorganizar el código cada vez. Queríamos
que agregar un dominio nuevo fuera lo más parecido a "instalar un pack".

Algunas piezas no son de un dominio sino compartidas: las lecciones de *Minna no Nihongo*
y las semanas del plan sirven tanto para kanji como para gramática, y el repaso de la v2
también será genérico.

## Opciones consideradas

### 1. Engines de Rails (mountable engines)

Cada pack es una mini aplicación empaquetada como gema (`engines/kanji_study/`), con sus
propios modelos, rutas, migraciones y tests. Se agrega al `Gemfile` y se monta en las rutas.

- ✅ Lo más parecido a "instalar un pack": aislamiento real, se podría publicar como gema.
- ❌ Mucha ceremonia: cada engine necesita su app de prueba (`test/dummy`), las migraciones
  se copian a la app con `bin/rails kanji_study:install:migrations`, las tablas quedan con
  prefijo (`kanji_study_kanjis`) y hay que configurar Tailwind para que lea las vistas de
  cada engine.
- ❌ Sobredimensionado para una app personal con un solo desarrollador.

### 2. Packs dentro de la misma app (`packs-rails`) ← elegida

Cada pack es una carpeta `packs/<nombre>/` con su propio `app/models`, `app/controllers`,
`app/views` y `test/`. La gema `packs-rails` hace que Rails (Zeitwerk) cargue esas carpetas
como si fueran parte de `app/`. Cada pack declara sus dependencias en un `package.yml`.

- ✅ Límites de dominio claros y visibles en la estructura de carpetas.
- ✅ Agregar un dominio = crear `packs/grammar_study/`.
- ✅ Una sola app, una sola base de datos, un solo set de tests: poco costo.
- ✅ Si más adelante queremos que los límites se cumplan automáticamente (que `grammar_study`
  no use clases de `kanji_study`), se agrega [Packwerk](https://github.com/Shopify/packwerk),
  que lee los mismos `package.yml`.
- ✅ Si un pack necesita volverse gema real, pasar de pack a engine es directo.
- ❌ No se "instala" como una gema; es una convención dentro del repo.

### 3. Solo namespaces dentro de `app/`

Todo en `app/`, separado por módulos (`app/models/kanji_study/kanji.rb`).

- ✅ Lo más simple; es Rails estándar.
- ❌ Los límites entre dominios dependen solo de la disciplina; nada los hace visibles
  ni los verifica.

## Decisión

Usamos **packs dentro de la misma app** con `packs-rails`:

```
packs/
  core/          Lesson, PlanWeek (y en la v2, el repaso genérico)
  kanji_study/   Kanji, lecturas, palabras, piezas, grupos para distinguir, kanji sabidos
                 → depende de core
  # futuro: grammar_study/ → depende de core, no de kanji_study
app/             layout, estilos y lo transversal
```

- El namespace del pack de kanji es `KanjiStudy` y no `Kanji`, para no terminar con
  `Kanji::Kanji`.
- Las migraciones quedan en `db/migrate/` (una sola base de datos).
- Packwerk no se instala en la v1; se evaluará cuando exista un segundo dominio.

## Consecuencias

- Hay que configurar Tailwind para que escanee `packs/**/app/views` además de `app/views`.
- Los tests viven dentro de cada pack (`packs/kanji_study/test/`) y se corren junto con
  los de la app.
- Las rutas de cada pack viven en `packs/<pack>/config/routes/<pack>.rb` y se cargan con
  `draw(:<pack>)` en `config/routes.rb`.
- Cuando `core` necesita mostrar algo de un dominio (por ejemplo, los kanji en la página
  de una semana), ofrece un **punto de extensión** en vez de depender del dominio:
  `PlanWeekSections`, donde cada pack registra su partial. Las claves foráneas desde los
  dominios hacia `core` usan `on_delete: :nullify`, para que `core` pueda borrar semanas
  o lecciones sin conocer las tablas que las referencian.
- `packs-rails` no integra Minitest: `config/boot.rb` define `DEFAULT_TEST` para que
  `bin/rails test` incluya `packs/*/test`, y `test_helper.rb` agrega sus fixtures.
