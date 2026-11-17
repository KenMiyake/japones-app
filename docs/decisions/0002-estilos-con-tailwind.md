# 0002. Estilos con Tailwind CSS

- **Estado:** aceptada
- **Fecha:** 2026-11-16

## Contexto

La app es mayormente formularios, tablas y listados (gestión de contenido), con algunos
componentes a medida: la ficha del kanji en grande, la cuadrícula de kanji sabidos, la vista
imprimible y, en la v2, las tarjetas de repaso.

En el trabajo se usa SCSS sobre Bootstrap 4 con un design system propio, así que practicar
ese stack tenía valor. Al mismo tiempo, el objetivo del proyecto incluye aprender lo que
hoy se usa en Rails y Hotwire.

## Opciones consideradas

| | Bootstrap 5 + SCSS | Tailwind | CSS moderno a mano | Pico (sin clases) |
|---|---|---|---|---|
| Resultado rápido en un CRUD | Alto: formularios, tablas y alertas listos | Medio: hay que diseñar cada componente | Bajo | Alto, con poco control |
| Escala en apps grandes | Media: pelear con los overrides | Alta: no acumula CSS muerto | Depende de la disciplina | Baja |
| Uso en la industria (proyectos nuevos) | Medio (muy usado en apps existentes) | El más usado y mejor valorado (State of CSS) | Bajo | Bajo |
| Transferencia al trabajo | Directa | Baja | Media | Nula |
| Encaje con Hotwire | Bueno (BS5 no usa jQuery) | Muy bueno | Bueno | Bueno |
| Dependencias | Node para compilar SCSS | Binario propio, sin Node | Ninguna | Ninguna |

Notas:

- Bootstrap 4 se descartó de entrada: está sin soporte desde enero de 2023 y depende de
  jQuery, que choca con Turbo.
- `rails new` por defecto genera CSS plano; Tailwind es una opción (`--css tailwind`),
  la más usada en proyectos Rails nuevos. 37signals (autores de Rails y Hotwire) usa
  CSS moderno sin framework en sus productos.

## Decisión

Usamos **Tailwind CSS** vía `tailwindcss-rails`, priorizando lo que se usa hoy en la
industria y la comodidad para componentes a medida.

Para no perder el aprendizaje de Bootstrap 5 + SCSS, el README tiene una sección
"Aprendizajes" donde, a medida que construimos componentes, se anota su equivalente en
Bootstrap 5 + SCSS.

## Consecuencias

- La imagen de Docker no necesita Node.
- Tailwind debe escanear las vistas de los packs (`packs/**/app/views/**/*`); ver ADR 0001.
- Los componentes que se repiten (botones, badges, inputs) se extraen a partials o helpers
  para no duplicar listas largas de clases.
- La tipografía para kanji (Noto Sans JP / Noto Serif JP) se define como fuente propia en
  la configuración de Tailwind.
