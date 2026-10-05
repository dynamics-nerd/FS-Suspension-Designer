# Sistema de coordenadas

## Marco del vehículo

El marco interno es cartesiano y diestro:

- **X**: longitudinal, positivo hacia delante.
- **Y**: lateral, positivo hacia la izquierda del vehículo visto en el sentido de marcha.
- **Z**: vertical, positivo hacia arriba.

Por tanto, `X × Y = Z`. Esta elección completa la dirección lateral que el requisito inicial dejaba abierta y es compatible con la convención del sistema de vehículo de ISO 8855. ISO 8855:2011 sigue vigente tras su confirmación en 2024, pero el proyecto documenta aquí su propia convención y no depende de que el usuario posea el estándar.

Los puntos y vectores se almacenan como coordenadas `[x, y, z]` en unidades internas. Las ecuaciones usan vectores columna cuando realizan álgebra lineal; un conjunto de `N` puntos se almacena como una matriz `N×3` por eficiencia y legibilidad en MATLAB.

## Lados y esquinas

Los identificadores de esquina son:

- `FL`: front left.
- `FR`: front right.
- `RL`: rear left.
- `RR`: rear right.

Con Y positiva a la izquierda, los puntos izquierdos suelen tener `Y > 0` y los derechos `Y < 0`, siempre que el origen esté en el plano central. “Left” y “right” se definen desde el punto de vista del conductor mirando hacia delante.

Se define `sideSign = +1` para izquierda y `sideSign = -1` para derecha. No se deduce el lado únicamente del signo de Y: un punto puede estar sobre el plano central y futuros mecanismos pueden cruzarlo. El ID de esquina es la fuente de verdad.

## Origen recomendado

Se recomienda un datum ligado al vehículo y no a estados variables:

- `X = 0`: plano del centro nominal del eje delantero;
- `Y = 0`: plano longitudinal de simetría del vehículo;
- `Z = 0`: plano de suelo nominal en condición de referencia.

Así, el eje trasero queda normalmente en X negativa. No se recomienda usar el centro de gravedad como origen porque puede variar con la configuración y la carga.

> **OPEN DECISION CS-001 — Vehicle origin:** aprobar el datum recomendado o sustituirlo por otro datum de diseño antes de publicar el schema v0.1. Hasta decidirlo, todo dataset deberá incluir una descripción explícita de su origen; no se asumirá uno silenciosamente.

## Coordenadas de una esquina

La fuente de verdad será siempre el marco del vehículo. Para inspección local puede usarse un marco **traducido** cuyo origen sea un punto declarado de la esquina y cuyos ejes permanezcan paralelos a X/Y/Z del vehículo. Ese marco sigue siendo diestro y Y sigue apuntando a la izquierda; no redefine Y como “hacia fuera”.

Para comparar simetría puede definirse una representación normalizada:

`[x, yOut, z] = [x, sideSign*y, z]`

Esta operación hace que `yOut` sea positivo hacia fuera en ambos lados. En el lado derecho su matriz tiene determinante `-1`: es una **reflexión, no una rotación**. No debe utilizarse como frame físico para productos vectoriales, momentos, ángulos firmados ni composición de orientaciones.

## Simetría izquierda/derecha

La reflexión geométrica respecto del plano central es:

`p_mirror = diag([1, -1, 1]) * p`

cuando el punto está expresado respecto de un origen situado en ese plano. Si no lo está, primero se traslada al plano, se refleja y se deshace la traslación. Los IDs `FL ↔ FR` y `RL ↔ RR` se cambian explícitamente.

Una reflexión de puntos polares no puede aplicarse sin más a vectores axiales, secuencias angulares o frames de orientación. Cada API futura deberá declarar qué transforma.

## Prevención de errores de signo

- Guardar geometría canónica en el marco del vehículo, no mezclar frames en una matriz.
- Exigir que toda API identifique frame y unidades en su contrato.
- Usar nombres `left/right`, `inboard/outboard` y `forward/aft`; evitar “positive/negative side” como semántica física.
- Centralizar reflexión y conversiones; no repetir cambios de signo en callbacks o solvers.
- Incluir tests de espejo, doble espejo e invariancia de distancias.
- Definir cada ángulo firmado antes de implementarlo; no inferir camber, toe, caster o KPI de convenciones externas.

> **OPEN DECISION CS-002 — Numerical tolerances:** fijar tolerancias absolutas y relativas por operación cuando se implemente v0.1. No se adopta todavía un único epsilon geométrico sin casos y escalas validados.

## Referencia

- [ISO 8855:2011 — Road vehicles — Vehicle dynamics and road-holding ability — Vocabulary](https://www.iso.org/standard/51180.html)

