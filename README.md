# FS Suspension Designer

Aplicación MATLAB para desarrollar y validar suspensiones de Formula Student con un núcleo de ingeniería independiente de App Designer y de herramientas externas.

## Estado actual

**v0.7 — Actuation Geometry & Kinematics** conserva v0.1–v0.6 e
implementa además:

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
- `SteeringSystemGeometry` limitado al eje `FRONT`, con rack axis 3D derivado
  de los inner tie-rod joints y referencia mínima del eje trasero;
- rack travel común en m/mm, inner joints móviles y separación rígida;
- steering combinado con wheel travel simétrico o asimétrico;
- continuation determinista: wheel travel primero y rack travel después;
- road-wheel angle absoluto, deflection desde estático y steering inducido
  exclusivamente por rack;
- scrub radius, mechanical trail y cruce steering-axis/plano de contacto;
- Ackermann geométrico mediante ICR sobre `X=rearAxleX`, incluyendo wheel
  stagger, static toe y estados near-straight;
- rack sweeps, visualización 3D y cinco curvas de steering.
- invalidez bilateral explícita ante fallo unilateral, conservando los
  diagnósticos de solver de cada esquina;
- golden regression de rack cero contra resultados independientes de v0.4.0.
- wheel travel de eje arbitrario `[left,right]`, con `solveAxleHeave` como
  wrapper compatible;
- body roll alrededor de `+X`, axle heave medio y cierre escalar contra los
  contactos geométricos reales de una carretera plana;
- sweeps de roll ordenados con continuation heave-first/roll-second;
- bracket local dentro del dominio alcanzable, con exploración bilateral
  independiente y refinamiento determinista de fronteras inválidas;
- camber relativo al chasis y relativo a carretera, FVIC y roll center en roll;
- altura perpendicular firmada del roll center respecto a carretera inclinada;
- wheel-center track, geometric-contact track y migración desde `h=0, phi=0`;
- visualización frontal de la carretera inclinada y curvas de roll.
- statuses cinemáticos y de análisis separados en sweeps con gaps.
- `ActuationGeometry` opcional por esquina para PUSHROD/PULLROD con attachment
  sobre UPRIGHT, UCA o LCA;
- rocker rígido alrededor de una línea 3D, presets YZ/XZ y eje CUSTOM;
- cierre analítico del actuation rod, selección de rama continua y diagnóstico
  de tangencia, falta de intersección y mecanismos underconstrained;
- rocker angle, longitud/compresión de damper, motion ratio, installation ratio,
  migración, stroke requerido y excursión angular;
- consumo directo de estados bump, steering, recorrido asimétrico y body roll,
  sin volver a resolver la suspensión;
- visualización 3D de actuación y cuatro curvas de sweep.

No calcula columna/volante/pinion, cierre simultáneo steering+roll, fuerzas o
compliance, pneumatic trail, spring/damper forces, wheel rate completo, ARB,
anti geometry, dinámica ni optimización.

## Convención

- X positivo hacia atrás, Y positivo hacia la derecha, Z positivo hacia arriba.
- Origen entre los contact patches delanteros sobre el suelo nominal.
- `wheelTravel = Z_WC,current - Z_WC,static`: positivo en bump y negativo en rebound.
- `bodyRollAngle > 0`: rotación de mano derecha alrededor de `+X`; la carretera
  vista en el frame del chasis cae hacia `+Y`.
- `axleHeave=(zLeft+zRight)/2`; no es todavía heave de vehículo completo.
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
steeringExample = steeringKinematicsExample(true);
actuationExample = actuationKinematicsExample(true);
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

steering = fsd.model.createSteeringSystem(axle, 1600, "mm");
steeringResult = fsd.kinematics.solveSteering( ...
    steering, 8, [15, 10], "mm");
steeringAnalysis = fsd.analysis.analyzeSteering(steering, steeringResult);
rackSweep = fsd.kinematics.solveRackSweep( ...
    steering, -20:2:20, 0, "mm");
rackAnalysis = fsd.analysis.analyzeRackSweep(steering, rackSweep);

travelResult = fsd.kinematics.solveAxleTravel( ...
    axle, [15, -10], "mm");
rollResult = fsd.kinematics.solveAxleRoll( ...
    axle, 2, 0, "deg", "mm");
rollAnalysis = fsd.analysis.analyzeAxleRoll(axle, rollResult);
rollSweep = fsd.kinematics.solveAxleRollSweep( ...
    axle, (-3:0.25:3)', 0, "deg", "mm");
rollCurves = fsd.analysis.analyzeAxleRollSweep(axle, rollSweep);

actuation = fsd.model.createActuationGeometry(geometry, definition, "mm");
actuationResult = fsd.kinematics.solveActuation(actuation, result);
actuationSweep = fsd.kinematics.solveActuationSweep(actuation, sweep);
actuationAnalysis = fsd.analysis.analyzeActuationSweep( ...
    actuation, actuationSweep);
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

Los contratos nuevos de steering usan schema `0.5.0`; los schemas de
v0.1–v0.4 permanecen sin cambios. El análisis de Ackermann no publica un
porcentaje y el mechanical trail no incluye pneumatic trail.

Los contratos nuevos de recorrido asimétrico, body roll y su análisis usan
schema `0.6.0`. Los schemas históricos siguen sin cambios. Ackermann continúa
definido en plan view del chasis y no se presenta como exacto durante roll.

Los contratos opcionales de actuación usan schema `0.7.0`. PUSHROD/PULLROD es
una identidad arquitectónica: con las mismas coordenadas produce exactamente
la misma cinemática. El modelo no calcula fuerzas ni valida tracción/compresión
estructural del rod.

## Aviso

**Software en desarrollo. Las geometrías de ejemplo no son targets de Formula Student ni deben utilizarse para fabricar o declarar segura una suspensión real.**
