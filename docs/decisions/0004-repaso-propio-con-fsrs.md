# 0004. Repaso propio con FSRS

- **Estado:** aceptada
- **Fecha:** 2026-11-23

## Contexto

El repaso de los kanji se hacía en Anki. La app ya guarda todo el contenido (significado,
lecturas, piezas, palabras, mnemotecnia, grupos para distinguir), así que el usuario decidió
que **la app reemplace a Anki desde ya**: el repaso con repetición espaciada se hace aquí.
El historial de Anki no se importa; los kanji que ya se saben entran como tarjetas en
repaso (vía "Sabidos").

## Decisiones

### Algoritmo: FSRS

Se usa **FSRS** (*Free Spaced Repetition Scheduler*), el algoritmo que Anki usa hoy por
defecto, en lugar de SM-2. Calcula para cada tarjeta su estabilidad y su dificultad, y
programa el próximo repaso para cuando la probabilidad de recordarla baje al 90 %.

### Implementación: la gema `fsrs_ruby` 1.0.0, detrás de un adaptador

| Opción | Por qué no / por qué sí |
|---|---|
| `fsrs` 0.9.2 | Mantenida en 2026, pero implementa FSRS 4.x (antiguo, pasos de aprendizaje fijos). |
| Escribirlo nosotros | Control total, pero sin vectores de referencia oficiales no habría cómo verificar los números. |
| **`fsrs_ruby` 1.0.0** ← elegida | FSRS-6, port de la implementación oficial en TypeScript. Sin dependencias en tiempo de ejecución. |

Revisión de seguridad hecha antes de agregarla:

- No carga ninguna biblioteca (ni siquiera de la librería estándar).
- No accede a archivos, red, variables de entorno ni procesos; no usa `eval`.
- Los únicos usos de reflexión son internos (`const_get` sobre sus propias constantes de
  calificación/estado y `send` para leer un campo de la tarjeta).

Mitigaciones:

- **Versión exacta** en el `Gemfile` (`"1.0.0"`): una versión futura comprometida no entra sola.
- El `Gemfile.lock` guarda el **checksum sha256** de la gema: si alguien alterara la 1.0.0,
  la instalación fallaría.
- **Adaptador** [`Srs::Scheduler`](../../packs/srs/app/services/srs/scheduler.rb): es el único
  código que conoce la gema. Cambiarla (o escribir el algoritmo a mano) toca un solo archivo.
- Tests propios del comportamiento esperado (pasos de aprendizaje, intervalos crecientes,
  olvidos, deshacer).

Riesgo conocido: es una gema poco usada, con una sola versión. Su propio informe reconoce
que en casos borde un intervalo puede salir un día distinto del de la versión TypeScript.
Para un uso personal es aceptable.

### Parámetros

Retención deseada 90 %, pasos de aprendizaje `1m 10m`, de reaprendizaje `10m` (los de Anki),
pesos por defecto de FSRS-6 y **sin fuzz** (sin variación aleatoria de intervalos, para
fechas predecibles). Están en `Srs::Scheduler::DEFAULTS`.

### Dónde vive: un pack nuevo, `srs`

El ADR 0001 decía que el repaso iría en `core`. Se prefirió un pack propio, `srs`, para que
`core` siga siendo chico. `srs` **no depende de ningún dominio**: una tarjeta apunta a lo que
se repasa con una relación polimórfica (`reviewable`), sea un kanji, un grupo para distinguir
o, en el futuro, un punto de gramática.

### Modelo

```
Srs::Card     reviewable (polimórfico), card_type,
              estado FSRS: state, due_at, stability, difficulty, elapsed_days,
              scheduled_days, learning_steps, reps, lapses, last_reviewed_at
Srs::Review   card, rating (again | hard | good | easy), reviewed_at,
              estado de la tarjeta ANTES del repaso (mismos campos)
```

Cada repaso se guarda con el estado previo de la tarjeta: permite **deshacer** el último
repaso y **recalcular** todo el historial si en el futuro cambian el algoritmo o sus pesos.

### Cómo entran las tarjetas nuevas

Siguiendo el plan: en el orden de las semanas, con un tope de nuevas por día (5 por defecto,
como los bloques diarios del plan). Se implementa en el paso R2.

## Consecuencias

- Pasos de implementación: R1 (este: modelos y adaptador), R2 (generación de tarjetas desde
  el plan y los sabidos), R3 (pantalla de repaso), R4 (tarjetas Escribir y Distinguir),
  R5 (estadísticas, olvidados e historial en la ficha).
- La v1 tenía previsto exportar a Anki; ya no hace falta.
- Si se agrega autenticación, `Srs::Card` necesitará un dueño (`user_id`): el progreso es
  por persona; el contenido puede seguir compartido.
