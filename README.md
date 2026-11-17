# japones-app

Gestor del contenido de kanji para estudiar japonés con *Minna no Nihongo I*, organizado
por lección y por semana de un plan de estudio de 8 semanas (S1–S8).

La v1 gestiona contenido (kanji, lecturas, palabras, piezas, grupos para distinguir y
kanji sabidos). El repaso con repetición espaciada queda para la v2.

## Stack

- Ruby 4.0 · Rails 8.1 · PostgreSQL 18
- Hotwire (Turbo + Stimulus) con importmap, sin build de JavaScript
- Tailwind CSS 4 (`tailwindcss-rails`)
- Código organizado en packs por dominio (`packs-rails`)
- Minitest
- Docker Compose para desarrollo

## Levantar el proyecto

Requisito: [Docker Desktop](https://www.docker.com/products/docker-desktop/).
No hace falta instalar Ruby ni PostgreSQL.

```sh
docker compose build
docker compose run --rm web bin/rails db:prepare
docker compose up
```

La app queda en <http://localhost:3000>.

Comandos útiles:

```sh
docker compose run --rm web bin/rails test       # tests (app + packs)
docker compose run --rm web bin/rubocop          # estilo
docker compose run --rm web bin/brakeman         # seguridad
docker compose run --rm web bin/rails console    # consola
docker compose down                              # detener (los datos de la base se conservan)
```

### Notas del entorno

- Los datos de PostgreSQL viven en un volumen de Docker (`pg_data`), fuera de la carpeta
  del proyecto, para que la sincronización de OneDrive no los toque.
- En Windows, Docker no avisa al contenedor cuando cambia un archivo, así que el watcher
  nativo de Tailwind no funciona. `bin/tailwind-watch` revisa los archivos cada segundo
  cuando `TAILWIND_POLL=1` (definido en `docker-compose.yml`).
- Si agregas gemas: `docker compose run --rm web bundle install` y luego
  `docker compose build`.
- `Dockerfile` es la imagen de producción (la generó Rails); `Dockerfile.dev` es la de
  desarrollo.

## Estructura

```
packs/
  core/          lecciones de Minna y semanas del plan
  kanji_study/   kanji, lecturas, palabras, piezas, grupos para distinguir, kanji sabidos
app/             layout, estilos y lo transversal
docs/decisions/  decisiones de arquitectura (ADR)
```

Cada pack tiene su propio `app/`, `config/routes/` y `test/`. Rails carga sus carpetas
como si fueran parte de `app/`, y `bin/rails test` corre también sus tests.

## Decisiones

- [0001 · Packs por dominio](docs/decisions/0001-packs-por-dominio.md)
- [0002 · Estilos con Tailwind](docs/decisions/0002-estilos-con-tailwind.md)
- [0003 · Modelo de datos de la v1](docs/decisions/0003-modelo-de-datos-v1.md)

## Cargar los datos iniciales

*Pendiente (paso 1 en adelante).*

## Aprendizajes: Tailwind vs. Bootstrap 5 + SCSS

La app usa Tailwind (ver ADR 0002). Para no perder la práctica del stack del trabajo,
aquí se anota cómo se haría cada componente con Bootstrap 5 + SCSS.

### Barra de navegación

**Tailwind** (`app/views/layouts/application.html.erb`): las clases describen el estilo
directamente en el HTML.

```erb
<header class="border-b border-stone-200 bg-white print:hidden">
  <nav class="mx-auto flex max-w-6xl items-center gap-6 px-5 py-3">
    <%= link_to root_path, class: "flex items-baseline gap-2" do %>
      <span class="font-kanji text-2xl">漢字</span>
      <span class="font-medium">Japonés</span>
    <% end %>
  </nav>
</header>
```

**Bootstrap 5 + SCSS**: se usa el componente `navbar` y se ajusta con variables y una
clase propia.

```erb
<nav class="navbar navbar-light bg-white border-bottom d-print-none">
  <div class="container">
    <%= link_to root_path, class: "navbar-brand" do %>
      <span class="kanji">漢字</span> Japonés
    <% end %>
  </div>
</nav>
```

```scss
// app/assets/stylesheets/_variables.scss — antes de importar Bootstrap
$font-family-sans-serif: "Noto Sans JP", system-ui, sans-serif;
$font-kanji: "Noto Serif JP", serif;

// app/assets/stylesheets/components/_kanji.scss
.kanji {
  font-family: $font-kanji;
  font-size: 1.5rem;
}
```

Diferencias:

- **Tema:** en Tailwind la fuente se define en `@theme` (CSS) y genera la utilidad
  `font-kanji`; en Bootstrap se sobrescriben variables SCSS *antes* de importar Bootstrap.
- **Impresión:** `print:hidden` (variante de Tailwind) ↔ `d-print-none` (utilidad de Bootstrap).
- **Contenedor:** `mx-auto max-w-6xl px-5` ↔ `.container`, que trae anchos fijos por breakpoint.
