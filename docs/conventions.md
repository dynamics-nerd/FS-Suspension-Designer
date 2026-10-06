# Convenciones

## Unidades

El núcleo utiliza SI: m, rad, N, kg y s. Las APIs de geometría y wheel travel aceptan `"m"` o `"mm"`; convierten en la frontera mediante `fsd.model.convertLengthToMetres`.

## Hardpoint IDs v0.2

Cada ID es `<CORNER>_<POINT_ROLE>`, con corner `FL`, `FR`, `RL` o `RR`. Son obligatorios:

- `UCA_FWD_CHASSIS`, `UCA_AFT_CHASSIS`, `UBJ`;
- `LCA_FWD_CHASSIS`, `LCA_AFT_CHASSIS`, `LBJ`;
- `TIE_ROD_INBOARD`, `TIE_ROD_OUTBOARD`;
- `WHEEL_CENTER`, `CONTACT_PATCH`.

`TIE_ROD` es el nombre técnico genérico también para una futura toe link trasera. `TIE_ROD_INBOARD` permanece fijo en v0.2 y `TIE_ROD_OUTBOARD` forma parte del upright rígido.

IDs estables y `displayName` continúan separados.

## Procedencia

`sourceKind` y `sourceNote` son `N×3`, una entrada para X/Y/Z. Los kinds admitidos son `KNOWN`, `ASSUMED`, `DERIVED` y `UNSPECIFIED`. No representan el estado futuro `FIXED/RANGE/FREE`.

## Upright rígido

Son solidarios UBJ, LBJ, `TIE_ROD_OUTBOARD`, Wheel Center, Contact Patch y wheel axis. UBJ/LBJ/tie-rod-outboard deben ser distintos y no collineales. No existe compliance.

## Wheel travel

`wheelTravel = Z_WC,current - Z_WC,static`:

- positivo: bump/jounce;
- negativo: rebound/droop;
- cero: estado estático.

## Wheel axis, camber y toe

El wheel axis unitario apunta interior→exterior. La pose actual lo obtiene rotando el eje estático con la misma matriz del upright.

Camber negativo significa parte superior hacia el centro; positivo, hacia fuera. El valor del núcleo está en radianes. La ecuación simétrica por lado está en `equations.md`.

Toe positivo significa toe-in y toe negativo significa toe-out. Se obtiene solo de la proyección XY del wheel axis; la componente Z debida a camber no puede crear toe ficticio. Los ejes nominales `[0,-1,0]` para FL/RL y `[0,+1,0]` para FR/RR producen toe cero.

## Steering axis, caster y kingpin inclination

El steering axis unitario apunta siempre desde LBJ hacia UBJ. Su componente Z no se fuerza a ser positiva: una geometría inusual sigue conservando el sentido físico LBJ→UBJ y se interpreta con `atan2`.

- caster positivo: UBJ desplazado hacia `+X` (parte trasera) respecto a LBJ;
- `kingpinInclination`/KPI positivo: extremo superior del eje hacia el centro del vehículo;
- en FR/RR, KPI positivo implica menor Y en UBJ; en FL/RL, mayor Y;
- caster y KPI se almacenan en radianes.

## Bump steer

```text
bumpSteer(z) = toe(z) - toe(0)
```

Se conservan por separado `staticToe_rad`, `toe_rad` y `bumpSteer_rad`. `toe(0)` procede de la geometría estática, aunque el sweep solicitado no incluya cero.

El primer punto y el punto más próximo a cero nunca sustituyen a `toe(0)`. Esto aplica igualmente a sweeps solo positivos, solo negativos o que salten directamente de rebound a bump.

## Convergencia y status

- `converged=true` exige exclusivamente `status="CONVERGED"` y payload físico finito y coherente.
- `converged=false` admite exclusivamente `NO_CONVERGENCE` o `NOT_ATTEMPTED`.
- Un resultado no convergido conserva target, causa, diagnósticos y referencia estática, pero estado móvil, pose calculada, wheel axis, travel logrado y métricas permanecen en `NaN`.
- Strings desconocidos o contradicciones entre flag y status invalidan el resultado completo.

`diagnostics.attempted` es booleano y no se deduce de iteraciones:

- `CONVERGED`: `attempted=true`, incluso para un estado exacto reutilizado;
- `NO_CONVERGENCE`: `attempted=true`, aunque el fallo ocurra antes de completar una iteración formal;
- `NOT_ATTEMPTED`: `attempted=false` y cero iteraciones, evaluaciones, pasos de continuation y exit flag.

Los corner IDs admiten un char row como `'FL'` o un string escalar no missing. Matrices char, arrays string y valores multidimensionales se rechazan.

## Solver

v0.2 usa `fsolve` de Optimization Toolbox. Configuración central:

- continuation step máximo: `0.005 m`;
- Function/Step/Optimality tolerance: `1e-12`;
- máximo 200 iteraciones y 2000 evaluaciones por paso.

Son parámetros numéricos, no límites físicos. Pueden sobrescribirse mediante un options struct validado. La aceptación final sigue las tolerancias dimensionales de `fsd.model.numericTolerances`.

## Visualización

El núcleo mantiene m/rad. Las funciones de plot convierten wheel travel a mm y ángulos a grados exclusivamente en la frontera de presentación.

## Decisiones aún abiertas

> **OPEN DECISION NM-001 — Actuation IDs:** elegir IDs de actuación al diseñar pushrod/pullrod.

> **OPEN DECISION NM-002 — Rocker representation:** definir el eje del rocker cuando se implemente actuación.
