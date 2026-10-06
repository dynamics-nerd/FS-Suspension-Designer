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

## Wheel axis y camber

El wheel axis unitario apunta interior→exterior. La pose actual lo obtiene rotando el eje estático con la misma matriz del upright.

Camber negativo significa parte superior hacia el centro; positivo, hacia fuera. El valor del núcleo está en radianes. La ecuación simétrica por lado está en `equations.md`.

## Solver

v0.2 usa `fsolve` de Optimization Toolbox. Configuración central:

- continuation step máximo: `0.005 m`;
- Function/Step/Optimality tolerance: `1e-12`;
- máximo 200 iteraciones y 2000 evaluaciones por paso.

Son parámetros numéricos, no límites físicos. Pueden sobrescribirse mediante un options struct validado. La aceptación final sigue las tolerancias dimensionales de `fsd.model.numericTolerances`.

## Decisiones aún abiertas

> **OPEN DECISION NM-001 — Actuation IDs:** elegir IDs de actuación al diseñar pushrod/pullrod.

> **OPEN DECISION NM-002 — Rocker representation:** definir el eje del rocker cuando se implemente actuación.

