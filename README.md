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

Cada pack tiene su propio `app/`, `config/routes/`, `config/locales/` y `test/`. Rails
carga sus carpetas como si fueran parte de `app/`, y `bin/rails test` corre también sus
tests.

`core` no depende de ningún dominio. Para que la página de una semana muestre los kanji,
`kanji_study` registra una sección en el punto de extensión `PlanWeekSections`
(`packs/kanji_study/config/initializers/plan_week_sections.rb`). Un pack nuevo (gramática)
agregaría la suya igual, sin tocar `core`.

> Si creas una carpeta nueva dentro de un pack (por ejemplo `app/helpers`), reinicia el
> servidor: Rails registra las carpetas de autocarga al arrancar.

## Decisiones

- [0001 · Packs por dominio](docs/decisions/0001-packs-por-dominio.md)
- [0002 · Estilos con Tailwind](docs/decisions/0002-estilos-con-tailwind.md)
- [0003 · Modelo de datos de la v1](docs/decisions/0003-modelo-de-datos-v1.md)

## Cargar los datos iniciales

```sh
docker compose run --rm web bin/rails db:seed
```

Carga desde `db/seeds/`:

| Archivo | Qué crea |
|---|---|
| `plan.csv` | Lecciones L01–L25 de Minna I y semanas S1–S8 (desde el lunes 16/11/2026, consecutivas) |
| `plan.csv` (columna `kanji`) | Los 196 kanji del plan, cada uno en su semana y en el orden del CSV, sin significado ni lecturas |

El seed es **idempotente y no destructivo**: crea solo lo que falta y nunca sobrescribe lo
que ya editaste en la app. Se puede volver a correr sin problema.

Para empezar de cero: `docker compose run --rm web bin/rails db:reset` (borra todo y
vuelve a sembrar).

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

### Insignia (badge) con variantes de color

**Tailwind** (`app/helpers/application_helper.rb`): como las listas de clases son largas,
se extraen a un helper y cada variante es un conjunto de clases.

```ruby
BADGE_TONES = {
  warning: "bg-amber-50 text-amber-800 ring-amber-300",
  info:    "bg-sky-50 text-sky-800 ring-sky-300"
}.freeze

def badge(text, tone: :neutral)
  tag.span(text, class: [
    "inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ring-1 ring-inset",
    BADGE_TONES.fetch(tone)
  ])
end
```

```erb
<%= badge "provisional", tone: :warning %>
```

**Bootstrap 5 + SCSS**: el componente ya existe; las variantes salen del mapa
`$theme-colors`, y un estilo propio se arma con un mixin que recorre ese mapa.

```erb
<span class="badge rounded-pill text-bg-warning">provisional</span>
```

```scss
// Variante "suave" propia, generada para todos los colores del tema
@each $name, $color in $theme-colors {
  .badge-soft-#{$name} {
    background-color: tint-color($color, 90%);
    color: shade-color($color, 40%);
    border: 1px solid tint-color($color, 50%);
  }
}
```

Diferencias:

- **Dónde vive la variante:** en Tailwind es un hash de Ruby que elige clases; en
  Bootstrap es CSS generado con `@each` sobre un mapa de SCSS.
- **Reutilización:** en Tailwind se reutiliza con helpers o partials (Ruby); en Bootstrap,
  con clases semánticas (`.badge-soft-warning`) y mixins (SCSS).
- **CSS resultante:** Tailwind solo incluye las clases que aparecen en el código; el `@each`
  de SCSS genera todas las variantes, se usen o no.

### Sidebar animado (colapsable y cajón en móvil)

**Tailwind + Stimulus** (`app/views/layouts/_sidebar.html.erb`,
`app/javascript/controllers/sidebar_controller.js`): el estado vive en atributos del
`<body>` (`data-collapsed`, `data-open`) y cada elemento reacciona con variantes de grupo.
El JS solo cambia atributos; la animación es CSS.

```erb
<body class="group/sidebar" data-controller="sidebar" <%= "data-collapsed" if sidebar_collapsed? %>>
  <aside class="w-sidebar transition-[width,translate] duration-300
                max-lg:-translate-x-full max-lg:group-data-open/sidebar:translate-x-0
                lg:group-data-collapsed/sidebar:w-sidebar-collapsed">
```

```js
toggleCollapsed() {
  const collapsed = !this.element.hasAttribute("data-collapsed")
  this.element.toggleAttribute("data-collapsed", collapsed)
  document.cookie = `sidebar_collapsed=${collapsed ? 1 : 0}; path=/`
}
```

**Bootstrap 5 + SCSS**: el cajón móvil ya existe (`offcanvas`, con su propio JS); el
colapso en escritorio no, así que se escribe en SCSS con una clase en el `<body>`.

```erb
<aside class="offcanvas-lg offcanvas-start sidebar" id="sidebar">
  <div class="offcanvas-body">…</div>
</aside>
<button class="btn d-lg-none" data-bs-toggle="offcanvas" data-bs-target="#sidebar">☰</button>
```

```scss
.sidebar {
  width: $sidebar-width;
  transition: width .3s ease-out;
  .label { transition: opacity .2s; }

  body.sidebar-collapsed & {
    width: $sidebar-collapsed-width;
    .label { opacity: 0; }
  }
  @media (prefers-reduced-motion: reduce) { transition: none; }
}
```

Diferencias:

- **Móvil:** Bootstrap trae `offcanvas` listo (backdrop, Esc, foco); en Tailwind se arma
  a mano con un controlador de Stimulus de pocas líneas.
- **Estado:** en ambos casos conviene un atributo o clase en el `<body>` guardado en una
  cookie, para que el servidor renderice el estado correcto y no haya parpadeo con Turbo.
- **Movimiento reducido:** `motion-reduce:transition-none` ↔ `@media (prefers-reduced-motion)`.
