# Qué hace cada archivo de la raíz

Una guía para orientarse en el repositorio: para qué sirve cada archivo de la raíz, quién
lo usa y cuándo hay que tocarlo. Al final hay un resumen de las carpetas, de los scripts
de `bin/` y de los archivos de `config/`.

## Índice

- [Ruby y Rails](#ruby-y-rails): `Gemfile`, `Gemfile.lock`, `.ruby-version`, `Rakefile`, `config.ru`, `package.yml`
- [Docker](#docker): `Dockerfile`, `Dockerfile.dev`, `docker-compose.yml`, `.dockerignore`
- [Desarrollo](#desarrollo): `Procfile.dev`
- [Git](#git): `.gitignore`, `.gitattributes`
- [Calidad](#calidad): `.rubocop.yml`
- [Documentación](#documentación): `README.md`
- [Carpetas de la raíz](#carpetas-de-la-raíz)
- [Anexo: `bin/`](#anexo-bin)
- [Anexo: `config/`](#anexo-config)

---

## Ruby y Rails

### `Gemfile`

**La lista de dependencias (gemas) de la app.** Cada línea `gem "…"` es una biblioteca de
Ruby: `rails`, `pg` (PostgreSQL), `turbo-rails`, `tailwindcss-rails`, `packs-rails`,
`rails-i18n`, `csv`… Los bloques `group :development, :test` agrupan las que solo se usan
al desarrollar o en los tests (RuboCop, Brakeman, Capybara).

- **Quién lo usa:** [Bundler](https://bundler.io), con `bundle install`.
- **Cuándo lo tocas:** al agregar o quitar una gema. Lo más simple es
  `docker compose run --rm web bundle add nombre_gema`, que edita el archivo y la instala.
  Después, `docker compose build`.

### `Gemfile.lock`

**Las versiones exactas que se instalaron**, de cada gema del `Gemfile` y de las que estas
necesitan. Si el `Gemfile` dice `gem "rails", "~> 8.1.4"`, el lock dice cuál quedó (`8.1.4.1`).
Garantiza que todos (tu máquina, Docker, producción) usen exactamente lo mismo.

- **Quién lo usa:** Bundler. Lo genera y lo actualiza él.
- **Cuándo lo tocas:** nunca a mano. Cambia solo al correr `bundle install`, `bundle add` o
  `bundle update`. Siempre se sube a git.

### `.ruby-version`

**La versión de Ruby del proyecto** (`ruby-4.0.9`).

- **Quién lo usa:** los gestores de versiones (mise, rbenv) para elegir el Ruby correcto al
  entrar a la carpeta, y como referencia para el `ARG RUBY_VERSION` de los Dockerfiles.
- **Cuándo lo tocas:** al actualizar Ruby (y entonces también los Dockerfiles).

### `Rakefile`

**El punto de entrada de las tareas de Rake.** Carga la app y todas sus tareas: las de Rails
(`db:migrate`, `db:seed`, `assets:precompile`, `tailwindcss:build`…) y las propias que se
pongan en `lib/tasks/*.rake`.

- **Quién lo usa:** `bin/rails <tarea>` y `bin/rake`.
- **Cuándo lo tocas:** casi nunca. Las tareas nuevas van en `lib/tasks/`.

### `config.ru`

**El archivo de arranque para el servidor web.** `.ru` viene de *rackup*: le dice al servidor
(Puma) que la aplicación a servir es `Rails.application`.

- **Quién lo usa:** Puma, al arrancar con `bin/rails server`.
- **Cuándo lo tocas:** prácticamente nunca.

### `package.yml`

**Declara la raíz como un pack** (el "pack raíz", lo que vive en `app/`). Cada pack de
`packs/` tiene su propio `package.yml` con sus dependencias. Ver el
[ADR 0001](decisions/0001-packs-por-dominio.md).

- **Quién lo usa:** `packs-rails` (para encontrar los packs) y, si se instala más adelante,
  Packwerk (para verificar que se respeten las dependencias).
- **Cuándo lo tocas:** si se activa `enforce_dependencies` con Packwerk.

> No tiene relación con el `package.json` de Node. Este proyecto no usa Node.

---

## Docker

### `Dockerfile`

**La imagen de producción.** La generó `rails new` y queda lista para el despliegue (que será
en otra etapa). Se construye en varias etapas:

1. **base:** Ruby 4.0 slim + `libjemalloc` (mejor manejo de memoria) + cliente de PostgreSQL;
   `RAILS_ENV=production`.
2. **build:** instala las herramientas de compilación, las gemas (sin las de desarrollo),
   precompila `bootsnap` y los assets (Tailwind incluido).
3. **final:** copia solo lo necesario para correr, con un usuario sin privilegios (`rails`),
   expone el puerto 80 y arranca con Thruster delante de Puma.

- **Quién lo usa:** `docker build` (y en el futuro, el pipeline de despliegue).
- **Cuándo lo tocas:** al preparar el despliegue o si una gema nueva necesita una biblioteca
  del sistema en producción.

### `Dockerfile.dev`

**La imagen de desarrollo.** Más simple: Ruby 4.0 slim con las herramientas de compilación,
`RAILS_ENV=development`, las gemas instaladas y `foreman`. No copia el código, porque
`docker-compose.yml` monta la carpeta del proyecto: lo que editas en tu máquina se ve al
instante dentro del contenedor.

- **Quién lo usa:** `docker compose build`.
- **Cuándo lo tocas:** si hace falta una biblioteca del sistema en desarrollo
  (`apt-get install …`).

### `docker-compose.yml`

**El entorno de desarrollo completo**: qué contenedores hay y cómo se conectan.

| Servicio | Qué es |
|---|---|
| `db` | PostgreSQL 18, con usuario y clave `postgres`. Sus datos viven en el volumen `pg_data`, y tiene un *healthcheck* para avisar cuando está lista. |
| `web` | La app (imagen de `Dockerfile.dev`). Monta la carpeta del proyecto en `/rails`, guarda las gemas en el volumen `bundle`, publica el puerto 3000, apunta a la base con `DB_HOST=db`, activa `TAILWIND_POLL=1` y arranca `bin/dev` (antes borra el PID viejo de Puma). Espera a que `db` esté sana. |

- **Quién lo usa:** `docker compose up`, `docker compose run --rm web …`, `docker compose down`.
- **Cuándo lo tocas:** para cambiar el puerto, agregar un servicio (Redis, por ejemplo) o
  una variable de entorno.

### `.dockerignore`

**Lo que no se copia a la imagen al construirla**: `.git`, logs, archivos temporales, claves
(`config/master.key`), archivos `.env`, los assets compilados. Hace la construcción más rápida
y evita meter secretos en la imagen.

- **Quién lo usa:** `docker build` / `docker compose build`.
- **Cuándo lo tocas:** si aparece una carpeta pesada o secreta que no deba entrar a la imagen.

---

## Desarrollo

### `Procfile.dev`

**Los procesos que levanta `bin/dev`**, uno por línea:

```text
web: bin/rails server -b 0.0.0.0 -p ${PORT:-3000} -P /tmp/server.pid
css: bin/tailwind-watch
```

- **web:** Puma escuchando en todas las interfaces (necesario dentro de Docker), con el PID en
  `/tmp`.
- **css:** recompila Tailwind cuando cambia una vista ([`bin/tailwind-watch`](../bin/tailwind-watch),
  por *polling* en Windows).

- **Quién lo usa:** `foreman` (lo llama `bin/dev`), que corre los dos procesos juntos y mezcla
  sus logs.
- **Cuándo lo tocas:** si se agrega otro proceso de desarrollo (por ejemplo, un worker de colas).

---

## Git

### `.gitignore`

**Lo que git no debe versionar**: logs (`log/*`), archivos temporales (`tmp/*`), los assets
compilados (`app/assets/builds/*`, `public/assets`), la configuración local de Bundler
(`.bundle`), los archivos `.env` y, sobre todo, las claves (`config/*.key`). Los `.keep`
mantienen las carpetas vacías dentro del repo.

- **Cuándo lo tocas:** si aparece un archivo generado o secreto que no deba subirse.

### `.gitattributes`

**Cómo trata git ciertos archivos:**

- `* text=auto eol=lf`: todos los archivos de texto se guardan con saltos de línea LF. En
  Windows, git tiende a convertirlos a CRLF, y los scripts de `bin/` dejan de funcionar
  dentro de Linux/Docker.
- `*.png`, `*.ico` como binarios (que no los toque).
- `db/schema.rb` marcado como generado y `vendor/*` como código de terceros (GitHub los
  oculta en los diffs y en las estadísticas de lenguajes).
- `diff=rails_credentials` para ver los diffs de las credenciales cifradas.

---

## Calidad

### `.rubocop.yml`

**La configuración de estilo de Ruby.** Hereda las reglas de `rubocop-rails-omakase` (el
estilo oficial de Rails) sin cambios.

- **Quién lo usa:** `bin/rubocop` (y `bin/rubocop -a` para corregir lo automático).
- **Cuándo lo tocas:** si se quiere relajar o agregar una regla para todo el proyecto.

---

## Documentación

### `README.md`

**La portada del repositorio**: de qué va la app, cómo levantarla con Docker, qué
funcionalidades tiene, el stack, la estructura, las decisiones, la carga de datos y los
aprendizajes de Tailwind vs. Bootstrap. Desde ahí se enlaza el resto de la documentación.

---

## Carpetas de la raíz

| Carpeta | Qué contiene |
|---|---|
| `app/` | Lo transversal: layout, sidebar y barra superior, la página de inicio, helpers de interfaz, los controladores de Stimulus (`app/javascript/controllers`) y la entrada de Tailwind (`app/assets/tailwind/application.css`). |
| `packs/` | Los dominios: `core` (lecciones y semanas) y `kanji_study` (kanji y todo lo relacionado). Cada uno con su `app/`, `config/`, `test/` y `README.md`. |
| `bin/` | Scripts ejecutables del proyecto (ver [anexo](#anexo-bin)). |
| `config/` | Configuración de Rails (ver [anexo](#anexo-config)). |
| `db/` | `migrate/` (migraciones), `schema.rb` (el esquema resultante, generado), `seeds.rb` y `seeds/*.csv` (datos iniciales). |
| `docs/` | Decisiones de arquitectura (`decisions/`), la guía desde cero, el flujo de la aplicación y este documento. |
| `test/` | Tests transversales (layout, sidebar, barra superior, inicio, helpers) y `test_helper.rb`. Los tests de cada dominio están en `packs/*/test/`. |
| `lib/` | Código que no es de la app en sí; `lib/tasks/` para tareas de Rake propias. Vacía por ahora. |
| `public/` | Archivos servidos tal cual: páginas de error (404, 422, 500), íconos y `robots.txt`. |
| `vendor/` | Código de terceros copiado al repo (`vendor/javascript` para módulos JS de importmap). Vacía por ahora. |
| `script/` | Scripts sueltos de mantenimiento. Vacía por ahora. |
| `log/`, `tmp/` | Logs y archivos temporales (caché, PIDs). Se ignoran en git, salvo su `.keep`. |

---

## Anexo: `bin/`

Siempre se ejecutan desde la raíz (dentro de Docker: `docker compose run --rm web bin/…`).

| Script | Qué hace |
|---|---|
| `bin/rails` | El comando de Rails: `server`, `console`, `generate`, `db:*`, `test`, `routes`… |
| `bin/rake` | Corre tareas de Rake (casi siempre basta `bin/rails`). |
| `bin/dev` | Levanta los procesos de `Procfile.dev` con `foreman`. Es lo que arranca `docker compose up`. |
| `bin/tailwind-watch` | Recompila Tailwind al cambiar archivos; con `TAILWIND_POLL=1` revisa cada segundo (necesario en Windows). Propio del proyecto. |
| `bin/setup` | Prepara el proyecto en una máquina nueva sin Docker (gemas, base de datos). |
| `bin/rubocop` | Revisa el estilo del código Ruby. |
| `bin/brakeman` | Análisis estático de seguridad. |
| `bin/bundler-audit` | Revisa si alguna gema tiene vulnerabilidades conocidas (lee `config/bundler-audit.yml`). |
| `bin/importmap` | Administra los módulos JS del importmap (`pin`, `audit`). |
| `bin/ci` | CI local de Rails 8.1: corre en orden los pasos de `config/ci.rb` (estilo, auditorías, tests, seeds). |
| `bin/docker-entrypoint` | Lo usa la imagen de producción: antes de arrancar el servidor corre `db:prepare`. |
| `bin/thrust` | Thruster, un proxy liviano delante de Puma en producción (compresión, caché de assets). |

## Anexo: `config/`

| Archivo | Qué configura |
|---|---|
| `application.rb` | La app: versión de defaults de Rails, frameworks cargados, zona horaria (Santiago), idioma (`es`). |
| `boot.rb` | Lo primero que corre: Bundler, Bootsnap y las variables `DEFAULT_TEST` para que `bin/rails test` incluya los packs. |
| `environment.rb` | Inicializa la app (lo cargan `config.ru` y los tests). |
| `environments/*.rb` | Ajustes por entorno: `development`, `test` y `production`. |
| `database.yml` | Conexión a PostgreSQL; toma host, usuario y clave de `DB_HOST`, `DB_USERNAME` y `DB_PASSWORD`. |
| `routes.rb` | Rutas generales; carga las de cada pack con `draw(:core)` y `draw(:kanji_study)` y define la raíz. |
| `importmap.rb` | Qué módulos JS se cargan y desde dónde (Turbo, Stimulus, los controladores). |
| `puma.rb` | Hilos y puerto del servidor web. |
| `initializers/` | Código que corre al arrancar (política de contenido, filtros de parámetros en logs, inflecciones). |
| `locales/` | Traducciones de la app; las de cada pack viven en `packs/*/config/locales/`. |
| `credentials.yml.enc` | Secretos cifrados (para producción). Se descifran con `config/master.key`, que **no** está en el repo y no debe subirse. |
| `cable.yml` | Configuración de Action Cable (websockets); sin uso por ahora. |
| `ci.rb` | Los pasos de `bin/ci`. |
| `bundler-audit.yml` | Vulnerabilidades a ignorar en `bin/bundler-audit` (ninguna real por ahora). |
