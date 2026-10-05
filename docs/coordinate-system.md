# Sistema de coordenadas

## Marco global del vehículo

La convención definitiva del proyecto es cartesiana y diestra:

- **X**: longitudinal, positivo hacia la parte trasera del vehículo.
- **Y**: lateral, positivo hacia la derecha del vehículo visto en el sentido de marcha.
- **Z**: vertical, positivo hacia arriba.

Se cumple `X × Y = Z`. Esta es una convención propia del proyecto; no se presenta como equivalente a ISO 8855.

Un punto se escribe `[x, y, z]`. Las APIs devuelven un punto como fila `1×3`; las colecciones se almacenan como matrices `N×3`, una fila por hardpoint.

## Origen global — CS-001 cerrada

El origen `[0,0,0]` está en el punto medio entre los contact patches delanteros, proyectado sobre el plano de suelo nominal, en la condición estática de referencia.

- línea de contact patches delanteros: `X ≈ 0`;
- línea de contact patches traseros: `X ≈ wheelbase`;
- lado izquierdo: `Y < 0`;
- lado derecho: `Y > 0`;
- suelo nominal: `Z = 0`;
- puntos sobre el suelo: `Z > 0`.

Ejemplos conceptuales, no datos embebidos en una esquina:

```text
FL_CONTACT_PATCH ≈ [0,         -frontTrack/2, 0]
FR_CONTACT_PATCH ≈ [0,         +frontTrack/2, 0]
RL_CONTACT_PATCH ≈ [wheelbase, -rearTrack/2,  0]
RR_CONTACT_PATCH ≈ [wheelbase, +rearTrack/2,  0]
```

## Lados y esquinas

- `FL`: front left.
- `FR`: front right.
- `RL`: rear left.
- `RR`: rear right.

“Left” y “right” se definen desde el conductor mirando hacia delante. El ID de esquina es la fuente de verdad; el lado no se infiere únicamente del signo Y.

Para operaciones laterales se usa `sideSign = -1` en `FL/RL` y `sideSign = +1` en `FR/RR`. Un eje de rueda nominal apunta aproximadamente a `[0,-1,0]` en el lado izquierdo y `[0,+1,0]` en el derecho.

## Coordenadas locales

La geometría canónica se almacena siempre en el marco global. Una vista local puede trasladar el origen, pero mantiene los ejes paralelos a X/Y/Z globales. No redefine Y como “outboard”.

Para comparaciones se puede definir `yOut = sideSign*y`. En el lado izquierdo esta operación es una reflexión, no una rotación; no debe usarse como frame físico para momentos, productos vectoriales u orientaciones.

## Reflexión izquierda/derecha

Respecto del plano central `Y = 0`:

```text
[x, y, z] -> [x, -y, z]
```

La transformación cambia `FL ↔ FR` y `RL ↔ RR`. También refleja `wheelAxis` cambiando el signo de su componente Y. Conserva X, Z, distancias y procedencia.

La matriz `diag([1,-1,1])` tiene determinante `-1`: es una reflexión y no una rotación propia.

## Tolerancias numéricas — CS-002 cerrada provisionalmente

- `AbsTol = 1e-9 m`.
- `RelTol = 1e-9`.

Están centralizadas en `fsd.model.numericTolerances`. Solo sirven para comparaciones de coma flotante. No representan tolerancias de fabricación, montaje, diseño u optimización.

Para coincidencia de dos puntos, v0.1 compara la distancia con:

`AbsTol + RelTol * max(norm(pA), norm(pB), 1 m)`

## Prevención de errores de signo

- No mezclar frames dentro de una misma matriz.
- Declarar frame y unidad en cada contrato persistente.
- Centralizar reflexión y conversión de unidades.
- No inferir convenciones de ángulos todavía no especificados.
- Probar reflexión, doble reflexión e invariancia de distancias.

