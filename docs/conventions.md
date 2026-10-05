# Convenciones

## Unidades — UN-001 cerrada

El núcleo almacena y procesa exclusivamente SI:

| Magnitud | Unidad interna |
|---|---:|
| Longitud | metro (`m`) |
| Ángulo | radián (`rad`) |
| Fuerza | newton (`N`) |
| Masa | kilogramo (`kg`) |
| Tiempo | segundo (`s`) |

El API de construcción v0.1 acepta longitudes con unidad explícita `"m"` o `"mm"`. La conversión ocurre una sola vez en `fsd.model.createDoubleWishboneGeometry`; el struct canónico conserva únicamente `xyz_m` y declara `metadata.lengthUnit = "m"`.

No existe todavía un sistema universal de unidades ni se aceptan unidades implícitas.

## Identificadores de hardpoints

El ID canónico es ASCII en `UPPER_SNAKE_CASE`:

`<CORNER>_<POINT_ROLE>`

v0.1 exige exactamente:

- `<CORNER>_UCA_FWD_CHASSIS`
- `<CORNER>_UCA_AFT_CHASSIS`
- `<CORNER>_UBJ`
- `<CORNER>_LCA_FWD_CHASSIS`
- `<CORNER>_LCA_AFT_CHASSIS`
- `<CORNER>_LBJ`
- `<CORNER>_WHEEL_CENTER`
- `<CORNER>_CONTACT_PATCH`

Se utiliza `FWD/AFT`, no `FRONT/REAR`, para evitar confundir un pivot posterior con el eje trasero. El ID estable se almacena por separado de `hardpoints.displayName`, que es solo presentación.

IDs desconocidos se rechazan en el schema v0.1; una ampliación futura requiere actualizar schema, documentación y tests.

## Procedencia — DM-003 cerrada

La procedencia es `N×3`, alineada con las columnas X/Y/Z:

```matlab
geometry.hardpoints.sourceKind  % N-by-3 string
geometry.hardpoints.sourceNote  % N-by-3 string
```

`sourceKind` admite `KNOWN`, `ASSUMED`, `DERIVED` y `UNSPECIFIED`. `sourceNote` puede registrar, por coordenada, una referencia como CAD, packaging u optimización. Si la procedencia opcional no se proporciona se usa `UNSPECIFIED`; no se inventa conocimiento.

La procedencia no es el estado de diseño futuro `FIXED/RANGE/FREE`.

## Wheel axis — NM-003 cerrada

`geometry.wheel.wheelAxis` es un vector real, finito, unitario `1×3` que apunta desde el interior del vehículo hacia el exterior de la rueda.

- esquina izquierda: componente Y negativa;
- esquina derecha: componente Y positiva.

El constructor normaliza cualquier vector no nulo y normalizable. El validador exige que la representación canónica ya sea unitaria y tenga una proyección lateral estrictamente hacia fuera. No se usa una matriz de rotación completa y no se representa el giro alrededor del eje.

## Decisiones aún abiertas

> **OPEN DECISION NM-001 — Actuation IDs:** elegir IDs genéricos `ACTUATION_*` o específicos `PUSHROD_*`/`PULLROD_*` cuando se diseñe actuación.

> **OPEN DECISION NM-002 — Rocker representation:** decidir si el eje del rocker se define mediante punto y dirección o mediante dos puntos.

