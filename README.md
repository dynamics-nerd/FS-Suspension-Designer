# FS Suspension Designer

Aplicación MATLAB para desarrollar y validar suspensiones de Formula Student con un núcleo de ingeniería independiente de App Designer y de herramientas externas.

## Estado actual

**v0.4 — Axle Geometry, Front-View Instant Centers & Roll Center** implementa:

- geometría double wishbone de una esquina con diez hardpoints, incluido tie rod/toe link;
- cierre físico del mecanismo mediante UCA, LCA y tie rod rígidos;
- pose 3D rígida del upright mediante rotation vector;
- wheel travel individual y sweep con continuation;
- Wheel Center, Contact Patch y wheel axis transformados rígidamente;
- camber, toe absoluto, bump steer, caster y kingpin inclination (KPI) con
  signo coherente FL/FR;
- análisis de un estado y de un sweep completo, conservando fallos como `NaN`;
- identidad canónica que impide analizar un resultado con otra geometría;
- validación completa de estados, status, campos redundantes y cinco constraints contra la identidad declarada;
- cinco curvas frente a wheel travel y tiempos separados de solver/análisis;
- diagnóstico explícito de convergencia;
- visualización estática/desplazada y persistencia MAT de la geometría.
- composición `FL+FR` o `RL+RR` en un `AxleGeometry` asimétrico;
- FVIC cinemático desde la velocidad instantánea proyectada de cada ball joint;
- intersecciones YZ proyectivas con estados finito, infinito, coincidente y
  degenerado, sin fabricar coordenadas remotas;
- contacto geométrico inferior de una rueda circular rígida ideal;
- roll center estático, coordenada Z y altura respecto al nivel común de contacto;
- heave simétrico y migración de roll center, conservando convergencia por lado;
- visualización frontal YZ y curvas de migración en mm.

No calcula body roll, steering input, rack travel, Ackermann, scrub radius,
trail, anti geometry, actuación, dinámica ni optimización.

## Convención

- X positivo hacia atrás, Y positivo hacia la derecha, Z positivo hacia arriba.
- Origen entre los contact patches delanteros sobre el suelo nominal.
- `wheelTravel = Z_WC,current - Z_WC,static`: positivo en bump y negativo en rebound.
- Longitudes internas en metros; entradas públicas de longitud en `"m"` o `"mm"`.
- Ángulos internos en radianes; las gráficas convierten únicamente para mostrar grados.
- Camber negativo: parte superior hacia el centro. Toe positivo: toe-in.
- Caster positivo: UBJ desplazado hacia `+X` respecto a LBJ.
- KPI positivo: extremo superior del steering axis hacia el centro del vehículo.

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
analysisExample = singleCornerAnalysisExample(true);
```

API principal:

```matlab
result = fsd.kinematics.solveBump(geometry, 20, "mm");
sweep = fsd.kinematics.solveBumpSweep(geometry, -30:5:30, "mm");
analysis = fsd.analysis.analyzeBumpSweep(geometry, sweep);

axle = fsd.model.createAxleGeometry(geometryFL, geometryFR);
staticRollCenter = fsd.analysis.rollCenter(axle);
leftFvic = fsd.analysis.frontViewInstantCenter(geometryFL);
axleSweep = fsd.kinematics.solveAxleHeaveSweep(axle, -30:5:30, "mm");
migration = fsd.analysis.analyzeAxleHeaveSweep(axle, axleSweep);
```

Si `result.converged` es falso, sus puntos y camber son `NaN`; la causa y los residuos permanecen en `result.diagnostics` y `result.failureReason`.

Cada `KinematicResult` y `BumpSweepResult` contiene `geometryIdentity`. Las APIs de análisis rechazan con `fsd:analysis:GeometryMismatch` cualquier combinación geometry/result que no tenga identidad exacta; nunca adaptan el resultado silenciosamente.

Además de comparar identidades, cada resultado convergido se valida físicamente contra las longitudes UCA FWD/AFT, LCA FWD/AFT y tie rod reconstruidas desde esa identidad. `diagnostics.attempted` distingue un solve fallido de un target no intentado.

## Estructura

- `src/+fsd/+model`: schema, validación, unidades y persistencia.
- `src/+fsd/+geometry`: geometría estática y transformaciones rígidas.
- `src/+fsd/+kinematics`: solver de bump, sweep y estados físicos.
- `src/+fsd/+analysis`: interpretación de estados y curvas derivadas.
- `tests`: tests estructurales, geométricos, del mecanismo y de signos analíticos.
- `examples`: ejemplos estático, cinemático y de análisis con datos ficticios.
- `docs`: decisiones, formulación y contratos.

## Compatibilidad

El constructor conserva su firma de v0.1. `DoubleWishboneGeometry` y
`SuspensionState` mantienen schema `0.2.0`; los contratos v0.2/v0.3 no se
alteran. Los nuevos modelos y resultados de eje usan schema `0.4.0`.
`CONTACT_PATCH` continúa siendo un datum material del upright; para análisis
de roll center debe además satisfacer explícitamente la precondición de rueda
circular ideal documentada en `docs/equations.md`.

El FVIC y el roll center de v0.4 son construcciones cinemáticas en YZ. No son
centros de fuerza ni dependen de un plano longitudinal de referencia.

## Aviso

**Software en desarrollo. Las geometrías de ejemplo no son targets de Formula Student ni deben utilizarse para fabricar o declarar segura una suspensión real.**
