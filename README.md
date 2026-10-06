# FS Suspension Designer

Aplicación MATLAB para desarrollar y validar suspensiones de Formula Student con un núcleo de ingeniería independiente de App Designer y de herramientas externas.

## Estado actual

**v0.2 — Bump Kinematics** implementa:

- geometría double wishbone de una esquina con diez hardpoints, incluido tie rod/toe link;
- cierre físico del mecanismo mediante UCA, LCA y tie rod rígidos;
- pose 3D rígida del upright mediante rotation vector;
- wheel travel individual y sweep con continuation;
- Wheel Center, Contact Patch y wheel axis transformados rígidamente;
- camber con signo coherente FL/FR;
- diagnóstico explícito de convergencia;
- visualización estática/desplazada y persistencia MAT de la geometría.

No calcula toe/bump steer, steering, caster, KPI, roll center, actuación, dinámica ni optimización.

## Convención

- X positivo hacia atrás, Y positivo hacia la derecha, Z positivo hacia arriba.
- Origen entre los contact patches delanteros sobre el suelo nominal.
- `wheelTravel = Z_WC,current - Z_WC,static`: positivo en bump y negativo en rebound.
- Longitudes internas en metros; entradas públicas de longitud en `"m"` o `"mm"`.
- Camber interno en radianes: negativo cuando la parte superior se inclina hacia el centro del vehículo.

## Requisitos

- MATLAB R2025b.
- **Optimization Toolbox**, utilizado por `fsolve` para el cierre no lineal.

Solo `src` debe añadirse al MATLAB path.

## Uso rápido

```matlab
setupProject
results = runProjectTests;

addpath("examples")
example = bumpKinematicsExample(true);
```

API principal:

```matlab
result = fsd.kinematics.solveBump(geometry, 20, "mm");
sweep = fsd.kinematics.solveBumpSweep(geometry, -30:5:30, "mm");
```

Si `result.converged` es falso, sus puntos y camber son `NaN`; la causa y los residuos permanecen en `result.diagnostics` y `result.failureReason`.

## Estructura

- `src/+fsd/+model`: schema, validación, unidades y persistencia.
- `src/+fsd/+geometry`: geometría estática y transformaciones rígidas.
- `src/+fsd/+kinematics`: solver de bump, sweep, camber y visualización desplazada.
- `tests`: tests estructurales, geométricos, de rotación y mecanismo.
- `examples`: ejemplos estático y cinemático con datos ficticios.
- `docs`: decisiones, formulación y contratos.

## Compatibilidad

El constructor conserva su firma de v0.1, pero el schema canónico pasa a `0.2.0` y exige `TIE_ROD_INBOARD` y `TIE_ROD_OUTBOARD`. Un MAT de schema 0.1 no se interpreta silenciosamente porque carece del constraint necesario para determinar la pose del upright.

## Aviso

**Software en desarrollo. Las geometrías de ejemplo no son targets de Formula Student ni deben utilizarse para fabricar o declarar segura una suspensión real.**

