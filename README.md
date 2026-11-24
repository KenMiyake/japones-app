# japones-app

## De qué va

Una app web para **preparar el contenido de kanji** de un curso de japonés basado en
*Minna no Nihongo I*. El estudio sigue un plan de 8 semanas (S1–S8, noviembre de 2026 a
enero de 2027) que reactiva 4–5 kanji por día, y el cuello de botella es escribir ese
contenido a tiempo. La app ayuda con eso:

- **Organiza los 196 kanji del plan** por semana y por lección del libro.
- **Guarda todo lo que hace falta para estudiar cada kanji:** significado, lecturas on/kun,
  piezas que lo componen, mnemotecnia y palabras de ejemplo.
- **Agrupa los kanji que se confunden** (人/入, 待/持/特) para practicarlos juntos.
- **Registra qué kanji ya sabes.**
- **Muestra qué falta completar,** semana a semana.

La v1 es solo de contenido y de uso personal (sin usuarios ni login). El repaso con
repetición espaciada queda para la v2.

## Levantar el proyecto con Docker

Solo necesitas **Docker**: Ruby, Rails y PostgreSQL corren dentro de contenedores.

### Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado y abierto (la
  ballena debe decir *Engine running*). En Windows, elige la versión **AMD64** salvo que tu
  equipo sea ARM, y deja activado WSL 2.
- Git.
- El puerto **3000** libre.

### Paso a paso (la primera vez)

**1. Clonar el repositorio**

```sh
git clone https://github.com/KenMiyake/japones-app.git
cd japones-app
```

**2. Construir la imagen de la app**

```sh
docker compose build
```

Crea la imagen `web` a partir de [`Dockerfile.dev`](Dockerfile.dev): Ruby 4.0, las
dependencias de compilación y las gemas del `Gemfile`. La primera vez tarda unos minutos;
las siguientes usa la caché.

**3. Crear la base de datos con los datos iniciales**

```sh
docker compose run --rm web bin/rails db:prepare
```

Levanta PostgreSQL (servicio `db`), espera a que esté listo, crea las bases de desarrollo y
test, aplica las migraciones y, como la base es nueva, **carga los datos iniciales**: las
lecciones L01–L25, las semanas S1–S8, los 196 kanji del plan y los 22 grupos para distinguir
(con sus 8 kanji de referencia). Al final imprime un resumen de lo creado. `run --rm` usa un
contenedor temporal que se borra al terminar.

> Si la base ya existía, `db:prepare` solo aplica migraciones. Para volver a cargar los
> datos iniciales: `docker compose run --rm web bin/rails db:seed` (no duplica ni sobrescribe
> nada).

**4. Levantar la app**

```sh
docker compose up
```

Arranca PostgreSQL, el servidor web y el recompilador de Tailwind. Cuando veas
`Listening on http://0.0.0.0:3000`, abre **<http://localhost:3000>**.

Para dejarla corriendo en segundo plano: `docker compose up -d` (y `docker compose logs -f web`
para ver los logs).

**5. Detener**

```sh
docker compose down
```

Detiene y borra los contenedores. **Los datos se conservan** en el volumen `pg_data`.

### El día a día

```sh
docker compose up        # levantar (Ctrl+C para detener)
```

No hace falta repetir los pasos 2 y 3, salvo en estos casos:

| Si… | Corre |
|---|---|
| Alguien agregó una migración (después de un `git pull`) | `docker compose run --rm web bin/rails db:migrate` |
| Cambió el `Gemfile` | `docker compose run --rm web bundle install` y `docker compose build` |
| Quieres empezar de cero (borra **todos** tus datos) | `docker compose run --rm web bin/rails db:reset` |

### Comandos útiles

```sh
docker compose run --rm web bin/rails test       # tests (app + packs)
docker compose run --rm web bin/rubocop          # estilo
docker compose run --rm web bin/brakeman         # seguridad
docker compose run --rm web bin/rails console    # consola de Rails
docker compose run --rm web bin/rails routes     # rutas
docker compose restart web                       # reiniciar solo la app
```

### Problemas frecuentes

| Síntoma | Qué hacer |
|---|---|
| `Cannot connect to the Docker daemon` o `docker` no responde | Abre Docker Desktop y espera a *Engine running*. Si sigue colgado: ciérralo, corre `wsl --shutdown` (Windows) y ábrelo otra vez. |
| `port is already allocated` (3000) | Otro programa usa el puerto. Ciérralo o cambia `"3000:3000"` por `"3001:3000"` en `docker-compose.yml`. |
| `A server is already running` | Ya está resuelto en `docker-compose.yml`; si aparece, `docker compose down` y `docker compose up`. |
| Cambié una vista y el estilo nuevo no aparece | Espera un segundo y recarga: Tailwind recompila por polling. Si no, `docker compose restart web`. |
| Creé una carpeta nueva en un pack y Rails no la encuentra | `docker compose restart web` (Rails registra las carpetas al arrancar). |
| `bin/rails: not found` o errores raros en scripts en Windows | Los archivos quedaron con saltos de línea CRLF: `git config core.autocrlf false` y vuelve a clonar. |

### Notas del entorno

- Los datos de PostgreSQL viven en un volumen de Docker (`pg_data`), fuera de la carpeta
  del proyecto, para que una sincronización como OneDrive no los toque.
- En Windows, Docker no avisa al contenedor cuando cambia un archivo, así que el watcher
  nativo de Tailwind no funciona. [`bin/tailwind-watch`](bin/tailwind-watch) revisa los
  archivos cada segundo cuando `TAILWIND_POLL=1` (definido en `docker-compose.yml`).
- `Dockerfile` es la imagen de **producción** (la generó Rails); `Dockerfile.dev` es la de
  desarrollo.

## Funcionalidades

| Sección | Qué permite |
|---|---|
| 計画 Plan | Ver las 8 semanas (la actual y las provisionales marcadas). Cada semana muestra sus kanji, sus grupos para distinguir y sus lecciones. |
| 漢字 Kanji | Listar por semana (filtro sin recargar), ver la ficha y editar: significado, lecturas on/kun con okurigana, piezas, mnemotecnia, semana y lección. Avisa qué falta completar y si la lección no calza con la semana. |
| 言葉 Palabras | Palabras de ejemplo que se enlazan solas con sus kanji (電車 → 電, 車). Búsqueda mientras se escribe. |
| 部品 Piezas | Componentes de los kanji con tus propios nombres; se crean también desde el formulario del kanji. |
| 区別 Distinguir | Grupos de kanji que se confunden (人/入, 待/持/特) con su modo de práctica: tarjeta, papel o por confirmar. |
| 既知 Sabidos | Marcar qué kanji ya sabes, uno a uno o por semana. |

Detalle de modelos, reglas, rutas y Hotwire de cada pack:
[`core`](packs/core/README.md) · [`kanji_study`](packs/kanji_study/README.md).

¿Cómo se construye una app así desde cero? Ver la
[guía paso a paso](docs/guia-rails-desde-cero.md): instalar Ruby y Rails, crear la app,
Docker, modelos, Hotwire y packs.

## Stack

- Ruby 4.0 · Rails 8.1 · PostgreSQL 18
- Hotwire (Turbo + Stimulus) con importmap, sin build de JavaScript
- Tailwind CSS 4 (`tailwindcss-rails`)
- Código organizado en packs por dominio (`packs-rails`)
- Minitest
- Docker Compose para desarrollo

## Estructura

```
packs/
  core/          lecciones de Minna y semanas del plan
  kanji_study/   kanji, lecturas, palabras, piezas, grupos para distinguir, kanji sabidos
  srs/           repetición espaciada: tarjetas, repasos y el algoritmo FSRS
app/             layout, estilos y lo transversal
docs/decisions/  decisiones de arquitectura (ADR)
docs/guia-rails-desde-cero.md   cómo construir una app así, paso a paso
docs/flujo-de-la-aplicacion.md  cómo viaja una request y cómo funciona Hotwire
docs/archivos-de-la-raiz.md     para qué sirve cada archivo de la raíz
```

Cada pack tiene su propio README: [`core`](packs/core/README.md), [`srs`](packs/srs/README.md),
[`kanji_study`](packs/kanji_study/README.md).

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
- [0004 · Repaso propio con FSRS](docs/decisions/0004-repaso-propio-con-fsrs.md)

## Cargar los datos iniciales

```sh
docker compose run --rm web bin/rails db:seed
```

Carga desde `db/seeds/`:

| Archivo | Qué crea |
|---|---|
| `plan.csv` | Lecciones L01–L25 de Minna I y semanas S1–S8 (desde el lunes 23/11/2026, consecutivas) |
| `plan.csv` (columna `kanji`) | Los 196 kanji del plan, cada uno en su semana y en el orden del CSV, sin significado ni lecturas |
| `confusable_groups.csv` | Los 22 grupos para distinguir (tarjeta / papel / por confirmar) y los 8 kanji de referencia que no están en el plan (人 日 目 干 会 小 大 水) |

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
