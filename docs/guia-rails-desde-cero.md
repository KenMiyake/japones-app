# Guía: una app Rails desde cero hasta los packs

Cómo se construye una app como esta, paso a paso y en orden: instalar Ruby y Rails,
crear la app, contenerizarla, escribir el primer dominio al estilo Rails clásico, sumar
Hotwire y, por último, reorganizar el código en **packs**.

Cada paso dice **qué correr**, **qué hace** y **cómo comprobar** que salió bien. Los
ejemplos salen de este repositorio; donde conviene, se enlaza el archivo real en vez de
repetirlo.

> Versiones usadas: Ruby 4.0.9, Rails 8.1.4.1, PostgreSQL 18, Tailwind 4,
> packs-rails 0.1.1 (noviembre de 2026). Si usas otras, ajusta los números.

## Índice

0. [Elegir el camino](#0-elegir-el-camino)
1. [Preparar el entorno](#1-preparar-el-entorno)
2. [Crear la app](#2-crear-la-app)
3. [Docker para desarrollo](#3-docker-para-desarrollo)
4. [El primer dominio, al estilo Rails clásico](#4-el-primer-dominio-al-estilo-rails-clásico)
5. [Hotwire, de menos a más](#5-hotwire-de-menos-a-más)
6. [Pasar a packs](#6-pasar-a-packs)
7. [Un segundo pack con namespace](#7-un-segundo-pack-con-namespace)
8. [Resumen de comandos](#8-resumen-de-comandos)
9. [Errores que aparecieron en este proyecto](#9-errores-que-aparecieron-en-este-proyecto)

---

## 0. Elegir el camino

Hay dos formas de trabajar. Elige una antes de empezar:

| | Camino A: nativo | Camino B: solo Docker |
|---|---|---|
| Qué instalas | Ruby, Rails y PostgreSQL en tu máquina (o en WSL) | Solo Docker Desktop |
| Ventajas | Comandos más rápidos; las herramientas del editor ven las gemas | Nada que instalar ni que se rompa en tu sistema; igual en cualquier máquina |
| Desventajas | Más pasos de instalación | Cada comando va con `docker compose run`; en Windows hay detalles con los archivos (ver paso 3) |

Este proyecto usó el **camino B**, porque la máquina no tenía Ruby. La guía cubre los dos:
el paso 1 es solo para el camino A, y el paso 2.1 muestra cómo generar la app con Docker.

**En Windows**, el camino A conviene hacerlo dentro de **WSL 2** (Linux dentro de Windows).
Ruby nativo en Windows funciona, pero muchas gemas y herramientas asumen Linux o macOS.

---

## 1. Preparar el entorno

*Solo camino A. Si vas por el camino B, instala [Docker Desktop](https://www.docker.com/products/docker-desktop/)
(en Windows, la versión AMD64 salvo que tu equipo sea ARM) y salta al [paso 2](#2-crear-la-app).*

### 1.1 (Windows) Instalar WSL 2 con Ubuntu

En PowerShell como administrador:

```powershell
wsl --install -d Ubuntu
```

- **Qué hace:** activa WSL 2 e instala Ubuntu. Pide reiniciar y luego crear un usuario de Linux.
- **Desde aquí**, todos los comandos se corren **dentro de Ubuntu** (abre "Ubuntu" desde el
  menú Inicio). Guarda tus proyectos en el sistema de archivos de Linux (`~/code/...`), no en
  `/mnt/c/...`: es mucho más rápido.
- **Comprobar:** `wsl -l -v` en PowerShell muestra Ubuntu con versión 2.

### 1.2 Dependencias del sistema

Ruby se compila desde el código fuente y necesita compiladores y bibliotecas.

**Ubuntu / WSL:**

```sh
sudo apt update
sudo apt install -y build-essential git curl rustc libssl-dev libyaml-dev zlib1g-dev libgmp-dev libpq-dev
```

**macOS** (con [Homebrew](https://brew.sh)):

```sh
xcode-select --install
brew install openssl@3 libyaml gmp rust libpq
```

- **Qué hace:** instala el compilador de C, Git, las bibliotecas que usa Ruby (SSL, YAML,
  compresión, números grandes) y `libpq`, que necesita la gema `pg` para hablar con PostgreSQL.
  `rustc` permite compilar Ruby con YJIT, su compilador JIT.

### 1.3 Instalar un gestor de versiones: mise

No conviene instalar Ruby "a mano": cada proyecto puede necesitar una versión distinta.
[mise](https://mise.jdx.dev) instala y cambia versiones de Ruby (y de otros lenguajes).

```sh
curl https://mise.run | sh
echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc   # en zsh: ~/.zshrc y "activate zsh"
source ~/.bashrc
```

- **Qué hace:** descarga mise y lo activa en cada terminal nueva.
- **Comprobar:** `mise --version`.

### 1.4 Instalar Ruby

```sh
mise use --global ruby@4.0
```

- **Qué hace:** descarga y compila Ruby 4.0 (tarda unos minutos) y lo deja como versión
  por defecto. Dentro de un proyecto, el archivo `.ruby-version` fija la versión exacta.
- **Comprobar:** `ruby -v` → `ruby 4.0.x`.

### 1.5 Instalar Rails

```sh
gem install rails -v 8.1.4.1
```

- **Qué hace:** instala la gema `rails`, que trae el comando `rails new`. Una vez creada la
  app, las versiones las fija su `Gemfile.lock`, no esta instalación global.
- **Comprobar:** `rails -v` → `Rails 8.1.4.1`.

### 1.6 PostgreSQL

La forma más simple, aun en el camino A, es correr PostgreSQL en Docker:

```sh
docker run -d --name pg -p 5432:5432 \
  -e POSTGRES_PASSWORD=postgres \
  -v pg_data:/var/lib/postgresql \
  postgres:18
```

- **Qué hace:** levanta PostgreSQL 18 en segundo plano en el puerto 5432, con usuario
  `postgres` / clave `postgres`, y guarda los datos en el volumen `pg_data` (sobreviven a
  reinicios del contenedor).
- **Alternativa nativa:** `sudo apt install postgresql` (Ubuntu) o
  `brew install postgresql@18 && brew services start postgresql@18` (macOS).
- **Comprobar:** `docker ps` muestra el contenedor `pg` en estado `Up`.

---

## 2. Crear la app

### 2.1 Generar el esqueleto

**Camino A:**

```sh
mkdir -p ~/code && cd ~/code
rails new japones_app -d postgresql --css tailwind \
  --skip-kamal --skip-solid --skip-ci \
  --skip-action-mailbox --skip-action-text --skip-active-storage --skip-jbuilder
cd japones_app
```

**Camino B** (genera la app en la carpeta actual usando un contenedor de Ruby):

```sh
mkdir japones_app && cd japones_app
docker run --rm -v "$(pwd):/app" -w /app ruby:4.0-slim bash -c "
  apt-get update -qq && apt-get install -y -qq build-essential git libpq-dev libyaml-dev pkg-config &&
  gem install rails -v 8.1.4.1 &&
  rails new . --name=japones_app -d postgresql --css tailwind \
    --skip-kamal --skip-solid --skip-ci \
    --skip-action-mailbox --skip-action-text --skip-active-storage --skip-jbuilder"
```

> En Git Bash para Windows, antepón `MSYS_NO_PATHCONV=1` y usa `$(pwd -W)` para que la ruta
> del volumen llegue bien a Docker.

Qué significa cada opción:

| Opción | Por qué |
|---|---|
| `-d postgresql` | Usa PostgreSQL en vez de SQLite (lo que se usará en producción). |
| `--css tailwind` | Instala `tailwindcss-rails` (binario propio, sin Node). Ver [ADR 0002](decisions/0002-estilos-con-tailwind.md). |
| `--skip-kamal` | Kamal es la herramienta de despliegue por defecto de Rails 8; el despliegue será otro. |
| `--skip-solid` | Omite Solid Queue / Cache / Cable (colas, caché y websockets en base de datos); no hacen falta todavía. |
| `--skip-ci` | Omite el workflow de GitHub Actions; se agrega en otra etapa. |
| `--skip-action-mailbox`, `--skip-action-text`, `--skip-active-storage` | Correo entrante, editor enriquecido y subida de archivos: no se usan. |
| `--skip-jbuilder` | Sin API JSON en esta etapa. |

- **Qué hace:** crea la estructura, el `Gemfile` con sus dependencias, corre `bundle install`,
  instala Turbo, Stimulus, importmap y Tailwind, y hace `git init`.
- **Comprobar:** existen `Gemfile.lock`, `bin/rails` y `app/assets/tailwind/application.css`.

### 2.2 Recorrido rápido de la estructura

| Carpeta | Qué hay |
|---|---|
| `app/models`, `app/controllers`, `app/views` | MVC clásico |
| `app/javascript/controllers` | Controladores de Stimulus |
| `app/assets/tailwind/application.css` | Entrada de Tailwind |
| `config/routes.rb` | Rutas |
| `config/database.yml` | Conexión a la base de datos |
| `db/migrate`, `db/schema.rb`, `db/seeds.rb` | Migraciones, esquema resultante y datos iniciales |
| `test/` | Minitest: modelos, controladores, fixtures |
| `bin/` | `rails`, `dev`, `rubocop`, `brakeman`… |
| `Dockerfile` | Imagen de **producción** (la genera Rails) |

### 2.3 Git: saltos de línea y primer commit

```sh
printf '\n* text=auto eol=lf\n' >> .gitattributes
git add -A
git commit -m "chore: app Rails generada"
```

- **Qué hace:** obliga a que los archivos queden con saltos de línea LF. En Windows, Git
  suele convertirlos a CRLF y los scripts de `bin/` dejan de funcionar dentro de Linux o Docker.
- **Si generaste la app con Docker en Windows:** corre también `git config core.filemode false`,
  porque el `git init` hecho dentro del contenedor deja una configuración pensada para Linux.

### 2.4 Conectar con PostgreSQL

En `config/database.yml`, dentro de `default:`, agrega:

```yaml
  host: <%= ENV.fetch("DB_HOST", "localhost") %>
  username: <%= ENV.fetch("DB_USERNAME", "postgres") %>
  password: <%= ENV.fetch("DB_PASSWORD", "postgres") %>
```

- **Qué hace:** toma la conexión de variables de entorno, con valores por defecto para
  desarrollo. Así funciona igual con PostgreSQL local (`localhost`) que en Docker (`db`).

### 2.5 Crear la base y levantar la app

```sh
bin/rails db:prepare
bin/dev
```

- **`db:prepare`:** crea las bases de desarrollo y test (si no existen) y corre las migraciones.
  Si acaba de crear la base, también corre `db/seeds.rb`; si ya existía, solo migra.
- **`bin/dev`:** usa `foreman` para levantar los procesos de `Procfile.dev`: el servidor web
  (Puma) y el watcher que recompila Tailwind cuando cambias una vista.
- **Comprobar:** <http://localhost:3000> muestra la página de bienvenida de Rails.

### 2.6 Español y zona horaria

```sh
bundle add rails-i18n csv
```

Y en `config/application.rb`:

```ruby
config.time_zone = "Santiago"
config.i18n.default_locale = :es
config.i18n.available_locales = [ :es ]
```

- **`rails-i18n`:** trae las traducciones de Rails (fechas, mensajes de validación) al español.
- **`csv`:** desde Ruby 3.4 ya no viene incluida y hay que agregarla para leer CSV.
- **Zona horaria:** afecta a `Date.current`; aquí decide cuál es "la semana actual".
- **Comprobar:** `bin/rails runner 'puts I18n.l(Date.current, format: :long)'` imprime la fecha en español.

---

## 3. Docker para desarrollo

Con Docker, quien clone el repo solo necesita Docker Desktop. Son dos archivos:

- [`Dockerfile.dev`](../Dockerfile.dev): imagen de Ruby con las dependencias de compilación;
  instala las gemas y arranca `bin/dev`.
- [`docker-compose.yml`](../docker-compose.yml): dos servicios, `db` (PostgreSQL 18 con un
  volumen con nombre) y `web` (la app, con la carpeta del proyecto montada en `/rails` y las
  gemas en un volumen `bundle`). `web` espera a que `db` esté sana (`healthcheck`).

```sh
docker compose build                              # construye la imagen web
docker compose run --rm web bin/rails db:prepare  # crea las bases dentro de Docker
docker compose up                                 # levanta db + web en http://localhost:3000
```

- **`run --rm web <comando>`:** corre un comando en un contenedor temporal de `web`. Es la forma
  de correr `bin/rails`, tests o la consola: `docker compose run --rm web bin/rails test`.
- **Si cambias el `Gemfile`:** `docker compose run --rm web bundle install` y después
  `docker compose build`.

Detalles que aparecieron en Windows:

| Problema | Solución en este repo |
|---|---|
| Docker no avisa al contenedor cuando cambia un archivo de Windows, así que el watcher de Tailwind no recompila. | [`bin/tailwind-watch`](../bin/tailwind-watch) revisa los archivos cada segundo cuando `TAILWIND_POLL=1`. |
| Tras `docker compose restart`, Puma dice "A server is already running". | El `command` de `web` borra `/tmp/server.pid` antes de arrancar. |
| La carpeta está sincronizada con OneDrive. | Los datos de PostgreSQL viven en un volumen de Docker, no en la carpeta. |

---

## 4. El primer dominio, al estilo Rails clásico

Antes de pensar en packs, conviene escribir el primer dominio como lo haría cualquier app
Rails, en `app/`. Aquí: lecciones (`Lesson`) y semanas del plan (`PlanWeek`).

### 4.1 Modelo y migración

```sh
bin/rails generate model Lesson number:integer:uniq title:string
```

- **Qué hace:** crea el modelo (`app/models/lesson.rb`), la migración (`db/migrate/…_create_lessons.rb`),
  el test y el fixture. `:uniq` agrega un índice único.
- **Antes de migrar, revisa la migración.** Agrega lo que el generador no sabe: `null: false`
  y restricciones. Ejemplo real: [`create_lessons.rb`](../db/migrate/20261117020243_create_lessons.rb).

```sh
bin/rails db:migrate
```

- **Qué hace:** aplica las migraciones pendientes y actualiza `db/schema.rb`.
- **Comprobar:** `bin/rails runner 'p Lesson.column_names'`.

### 4.2 Validaciones y comportamiento

Las reglas van en el modelo **y**, cuando se puede, también en la base de datos: el modelo da
buenos mensajes de error, y la base protege aunque alguien se salte el modelo.

```ruby
class Lesson < ApplicationRecord
  validates :number, presence: true, uniqueness: true,
                     numericality: { only_integer: true, greater_than: 0 }
  scope :ordered, -> { order(:number) }

  def code = format("L%02d", number) # "L07"
end
```

- **Comprobar en consola** (`bin/rails console`): `Lesson.new(number: 0).valid?` → `false`.

### 4.3 Datos iniciales (seeds)

Los datos de arranque van en `db/seeds.rb`. Que sean **idempotentes**, es decir, que se puedan
correr varias veces sin duplicar nada:

```ruby
(1..25).each { |number| Lesson.find_or_create_by!(number:) }
```

```sh
bin/rails db:seed
```

Cuando la carga crece, conviene moverla a una clase propia con tests, como
[`PlanSeeder`](../packs/core/app/services/plan_seeder.rb), que lee un CSV.

### 4.4 Rutas, controlador y vistas

```sh
bin/rails generate controller PlanWeeks index show --skip-routes
```

Y en `config/routes.rb`:

```ruby
resources :plan_weeks, only: %i[index show]
root "plan_weeks#index"
```

- **`resources`:** crea las rutas REST (`/plan_weeks`, `/plan_weeks/:id`) y sus helpers
  (`plan_weeks_path`, `plan_week_path(week)`).
- **Comprobar:** `bin/rails routes -g plan_week` lista las rutas.
- Las vistas usan clases de Tailwind directamente. Cuando una combinación se repite, se extrae
  a un helper o un partial (ver `badge` en [`application_helper.rb`](../app/helpers/application_helper.rb)).

### 4.5 Tests

```sh
bin/rails test                       # todos
bin/rails test test/models           # una carpeta
bin/rails test test/models/lesson_test.rb:12   # una línea
```

- **Fixtures:** datos de prueba en YAML (`test/fixtures/lessons.yml`), cargados en cada test
  dentro de una transacción que se deshace al terminar.
- **Tests de integración** (`ActionDispatch::IntegrationTest`): hacen requests reales y
  revisan el HTML con `assert_select`.

### 4.6 Calidad

```sh
bin/rubocop      # estilo (rubocop-rails-omakase); bin/rubocop -a corrige lo automático
bin/brakeman     # análisis de seguridad
```

### 4.7 Commit

```sh
git add -A
git commit -m "feat: lecciones y semanas del plan"
```

---

## 5. Hotwire, de menos a más

Hotwire hace que una app con HTML renderizado en el servidor se sienta como una SPA, casi
sin escribir JavaScript. Viene instalado con `rails new`.

### 5.1 Turbo Drive (ya está activo)

Cada link y cada formulario se resuelve con `fetch` y Turbo reemplaza el `<body>` sin
recargar la página. No hay que hacer nada. Dos reglas:

- Tras un POST, PATCH o DELETE exitoso, **redirige** (`redirect_to`, con `status: :see_other`
  en los DELETE).
- Si el formulario es inválido, responde con `status: :unprocessable_content` para que
  Turbo muestre el formulario con errores.

### 5.2 Turbo Frames: reemplazar solo una parte

```erb
<%= turbo_frame_tag "kanji_list" do %>
  <%= link_to "S3", kanjis_path(week: "S3"), data: { turbo_action: "advance" } %>
  …lista…
<% end %>
```

- Un link dentro del frame trae la página nueva, pero Turbo **solo reemplaza el frame**.
- `turbo_action: "advance"` actualiza también la URL.
- Para que un link salga del frame: `data: { turbo_frame: "_top" }`.
- Ejemplo real: el filtro por semana en [`kanjis/index`](../packs/kanji_study/app/views/kanji_study/kanjis/index.html.erb).

### 5.3 Turbo Streams: actualizar varias partes tras una acción

El controlador responde con formato `turbo_stream` y una vista `*.turbo_stream.erb`:

```ruby
respond_to do |format|
  format.turbo_stream                      # renderiza toggle.turbo_stream.erb
  format.html { redirect_back_or_to known_kanjis_path }
end
```

```erb
<%= turbo_stream.replace dom_id(@kanji, :known), method: :morph,
      partial: "kanji_study/known_kanjis/tile", locals: { kanji: @kanji } %>
<%= turbo_stream.replace "known_counter", method: :morph, partial: "kanji_study/known_kanjis/counter" %>
```

- Cada `turbo_stream.*` es una instrucción: `replace`, `update`, `append`, `remove`…
- **`method: :morph`** compara y modifica el elemento existente en vez de reemplazarlo: se
  conserva el foco y las transiciones CSS animan el cambio.
- Ejemplo real: [`toggle.turbo_stream.erb`](../packs/kanji_study/app/views/kanji_study/known_kanjis/toggle.turbo_stream.erb).

### 5.4 Stimulus: el poco JavaScript que hace falta

```sh
bin/rails generate stimulus search
```

- **Qué hace:** crea `app/javascript/controllers/search_controller.js`. Con importmap, se
  carga solo (no hay build).
- En el HTML se conecta con atributos `data-*`:

```erb
<%= form_with url: words_path, method: :get,
      data: { controller: "search", turbo_frame: "words_list" } do |f| %>
  <%= f.search_field :q, data: { action: "input->search#submit" } %>
<% end %>
```

Los controladores de este repo, de más simple a más complejo: `search` (debounce),
`flash` (aviso que se oculta), `dropdown`, `sidebar`, `nested-form` (filas anidadas) y
`tokens` (chips). Están en [`app/javascript/controllers/`](../app/javascript/controllers/).

---

## 6. Pasar a packs

### 6.1 Por qué y cuándo

Cuando aparece un segundo dominio (aquí: kanji, y más adelante gramática), `app/models` se
llena de clases de temas distintos. Un **pack** es una carpeta con su propio `app/`,
`config/` y `test/`, que Rails carga como si fuera parte de `app/`. Las opciones que se
evaluaron están en el [ADR 0001](decisions/0001-packs-por-dominio.md).

### 6.2 Instalar packs-rails

```sh
bundle add packs-rails
```

- **Qué hace:** agrega la gema en todos los entornos. Al arrancar, suma a Rails las carpetas
  `app/*`, `config/locales`, `config/initializers` y `config/routes` de cada `packs/*`.

### 6.3 Crear la estructura del pack

```sh
mkdir -p packs/core/app/{models,controllers,views,services} packs/core/config/routes packs/core/test/{models,controllers,fixtures}
printf 'enforce_dependencies: false\n' > package.yml
printf 'enforce_dependencies: false\ndependencies: []\n' > packs/core/package.yml
```

- **`package.yml`:** declara el pack y de quién depende. `enforce_dependencies` se activa si
  más adelante se usa Packwerk (paso 7.7).

### 6.4 Mover el código

```sh
git mv app/models/lesson.rb app/models/plan_week.rb packs/core/app/models/
git mv app/controllers/plan_weeks_controller.rb packs/core/app/controllers/
git mv app/views/plan_weeks packs/core/app/views/
git mv test/models/lesson_test.rb test/models/plan_week_test.rb packs/core/test/models/
git mv test/fixtures/lessons.yml test/fixtures/plan_weeks.yml packs/core/test/fixtures/
```

- **`git mv`** conserva el historial de cada archivo.
- Las clases **no cambian**: `Lesson` sigue siendo `Lesson`; solo cambia dónde vive el archivo.
- Los generadores de Rails siempre escriben en `app/`. Con packs, genera la migración
  (`bin/rails g migration …`, que va a `db/migrate`) y escribe o mueve el resto al pack.

### 6.5 Rutas por pack

```ruby
# packs/core/config/routes/core.rb
resources :plan_weeks, only: %i[index show]
```

```ruby
# config/routes.rb
Rails.application.routes.draw do
  draw(:core)
  root "plan_weeks#index"
end
```

- **`draw(:core)`** busca `config/routes/core.rb` en las rutas de configuración, que
  `packs-rails` extiende a cada pack.

### 6.6 Que los tests encuentren los packs

`packs-rails` trae integración con RSpec pero no con Minitest. Dos cambios:

```ruby
# config/boot.rb (antes de require "bundler/setup")
ENV["DEFAULT_TEST"] ||= "{test,packs/*/test}/**/*_test.rb"
ENV["DEFAULT_TEST_EXCLUDE"] ||= "{test,packs/*/test}/{system,dummy,fixtures}/**/*_test.rb"
```

```ruby
# test/test_helper.rb, dentro de ActiveSupport::TestCase
self.fixture_paths += Dir[Rails.root.join("packs/*/test/fixtures")]
fixtures :all
```

- **`DEFAULT_TEST`:** el runner de Rails lo usa como patrón de archivos de test.
- **`fixture_paths`:** carga los fixtures de cada pack además de los de `test/fixtures`.
- **Comprobar:** `bin/rails test` debe correr la misma cantidad de tests que antes de moverlos.

### 6.7 Que Tailwind vea las vistas de los packs

```css
/* app/assets/tailwind/application.css */
@import "tailwindcss";
@source "../../../packs";
```

- **Qué hace:** Tailwind solo genera las clases que encuentra en el código. `@source` le
  indica que también lea `packs/`.

### 6.8 Reiniciar y verificar

```sh
bin/rails runner 'puts ActiveSupport::Dependencies.autoload_paths.grep(/packs/)'
bin/rails test
```

- **Reinicia el servidor** cada vez que crees una carpeta nueva dentro de un pack (por
  ejemplo `app/helpers`): Rails registra las carpetas de autocarga al arrancar.

---

## 7. Un segundo pack con namespace

### 7.1 Módulo del pack y nombres relativos

```ruby
# packs/kanji_study/app/models/kanji_study.rb
module KanjiStudy
  def self.use_relative_model_naming? = true
end
```

```ruby
# packs/kanji_study/app/models/kanji_study/kanji.rb
module KanjiStudy
  class Kanji < ApplicationRecord
    self.table_name = "kanjis"
    belongs_to :plan_week, optional: true   # modelo de core, sin namespace
  end
end
```

- **Namespace:** el pack se llama `kanji_study` y su módulo `KanjiStudy`, así el modelo no queda
  `Kanji::Kanji`.
- **`use_relative_model_naming?`:** formularios, rutas y `dom_id` usan `kanji` en vez de
  `kanji_study_kanji` (`params[:kanji]`, `kanji_path`).
- **`self.table_name`:** la tabla es `kanjis`, sin prefijo.
- **Migración:** `bin/rails g migration CreateKanjis` y el modelo se escribe a mano. El generador
  de modelos con namespace crea una tabla con prefijo (`kanji_study_kanjis`), que aquí no se quiso.

### 7.2 Rutas con módulo

```ruby
# packs/kanji_study/config/routes/kanji_study.rb
scope module: :kanji_study do
  resources :kanjis
end
```

- **Qué hace:** la URL es `/kanjis` y el controlador `KanjiStudy::KanjisController`, con sus
  vistas en `packs/kanji_study/app/views/kanji_study/kanjis/`.

### 7.3 Traducciones del pack

`packs/kanji_study/config/locales/es.yml`, con las claves bajo `kanji_study/kanji`:

```yaml
es:
  activerecord:
    attributes:
      kanji_study/kanji:
        character: Kanji
```

> **Cuidado con YAML:** `On`, `Off`, `Yes`, `No` sin comillas se leen como booleanos.
> Escribe `"on": "On"`.

### 7.4 Fixtures con namespace

```yaml
# packs/kanji_study/test/fixtures/kanjis.yml
_fixture:
  model_class: KanjiStudy::Kanji

taberu:
  character: 食
  plan_week: s1     # referencia por nombre a un fixture de core
```

### 7.5 Constantes en vistas y helpers

- En **controladores, modelos y helpers** del módulo, `Kanji` se resuelve solo.
- En las **vistas**, no: escribe `KanjiStudy::Kanji` o, mejor, mueve la consulta a un helper o
  al controlador.

### 7.6 Dependencias entre packs

- `kanji_study` depende de `core` (`dependencies: [packs/core]` en su `package.yml`): puede
  usar `PlanWeek` y `Lesson`.
- `core` **no** depende de `kanji_study`. Cuando `core` necesita mostrar algo de kanji (los
  kanji en la página de una semana), ofrece un **punto de extensión**
  ([`PlanWeekSections`](../packs/core/app/services/plan_week_sections.rb)) donde el otro pack
  registra su partial desde un initializer.
- Las claves foráneas desde `kanji_study` hacia `core` usan `on_delete: :nullify`, para que
  `core` pueda borrar semanas sin conocer las tablas que las usan.

### 7.7 (Opcional) Hacer cumplir los límites con Packwerk

```sh
bundle add packwerk --group development
bundle exec packwerk init
# en cada package.yml: enforce_dependencies: true
bundle exec packwerk check
```

- **Qué hace:** analiza el código y avisa si un pack usa constantes de otro del que no
  declaró depender (por ejemplo, si `core` usara `KanjiStudy::Kanji`). En este repo todavía
  no se instaló; se evaluará cuando exista un segundo dominio.

---

## 8. Resumen de comandos

| Para… | Nativo | Docker |
|---|---|---|
| Levantar la app | `bin/dev` | `docker compose up` |
| Crear o actualizar la base | `bin/rails db:prepare` | `docker compose run --rm web bin/rails db:prepare` |
| Aplicar migraciones | `bin/rails db:migrate` | `docker compose run --rm web bin/rails db:migrate` |
| Cargar datos iniciales | `bin/rails db:seed` | `docker compose run --rm web bin/rails db:seed` |
| Borrar todo y volver a sembrar | `bin/rails db:reset` | `docker compose run --rm web bin/rails db:reset` |
| Consola | `bin/rails console` | `docker compose run --rm web bin/rails console` |
| Tests | `bin/rails test` | `docker compose run --rm web bin/rails test` |
| Estilo / seguridad | `bin/rubocop` / `bin/brakeman` | `docker compose run --rm web bin/rubocop` |
| Ver rutas | `bin/rails routes` | `docker compose run --rm web bin/rails routes` |
| Nueva migración | `bin/rails g migration CreateX` | `docker compose run --rm web bin/rails g migration CreateX` |
| Nuevo controlador de Stimulus | `bin/rails g stimulus nombre` | `docker compose run --rm web bin/rails g stimulus nombre` |
| Agregar una gema | `bundle add gema` | `docker compose run --rm web bundle add gema` y `docker compose build` |

---

## 9. Errores que aparecieron en este proyecto

| Síntoma | Causa | Solución |
|---|---|---|
| Docker no responde ni a `docker version` | Docker Desktop antiguo colgado con WSL 2 | Actualizar Docker Desktop; si sigue, `wsl --shutdown` y abrirlo de nuevo |
| Los scripts de `bin/` fallan dentro del contenedor | Saltos de línea CRLF | `* text=auto eol=lf` en `.gitattributes` y `core.autocrlf false` |
| Git marca todos los scripts como modificados | `core.filemode=true` (lo dejó el `git init` hecho en Linux) | `git config core.filemode false` |
| Tailwind no recompila al guardar | Docker en Windows no propaga los cambios de archivos | Watcher por polling (`bin/tailwind-watch`) |
| "A server is already running" tras reiniciar | PID viejo en `/tmp` del contenedor | Borrarlo en el `command` de `docker-compose.yml` |
| Un helper nuevo de un pack da `NoMethodError` en el navegador, pero los tests pasan | La carpeta se creó con el servidor corriendo | Reiniciar el servidor |
| Un local de un partial da "undefined local variable" | La firma `locals: (…)` estaba en un comentario con más texto | Ponerla sola: `<%# locals: (subtitle: nil) -%>` |
| Un select muestra "true" en vez de "On" | YAML lee `On` como booleano | Comillas: `"On"` |
| `uninitialized constant …::Kanji` en una vista | Las vistas no están dentro del módulo del pack | `KanjiStudy::Kanji` o mover la consulta a un helper |
| Una clase de Tailwind no gana (`text-sm` vs `text-7xl`) | Dos clases del mismo tipo: gana la que Tailwind genera después | Evitar el choque o usar `!` (`text-7xl!`) |
