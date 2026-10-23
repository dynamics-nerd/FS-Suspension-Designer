# FS Suspension Designer

Aplicación MATLAB para desarrollar y validar suspensiones de Formula Student con un núcleo de ingeniería independiente de App Designer y de herramientas externas.

## Estado actual

**v0.20.0 implementada y validada localmente — pendiente de auditoría independiente**,
actuación y mecánica guiadas, sobre la release estable
publicada v0.19.0 (`58ee34b`), rama activa `feature/v0.20-actuation-mechanics`.
Configuración PUSHROD/PULLROD, UPRIGHT/UCA/LCA y coilover nativo, análisis ACTUATION/
MECHANICAL, curvas y diagnósticos, síntesis de actuación con suspensión fija,
comparación/adopción coherente y MAT completo. Extensión mínima de la interfaz0.19;
SI interno, mm/grados en las nuevas vistas. No nuevos modelos estructurales.
Validación seleccionada:592/592 PASS (33 nuevos +559 históricos), Analyzer0/662;
inventario1987, no suite completa repetida. Núcleo físico histórico intacto.

```matlab
app = launchFSSuspensionDesigner;
% Ejemplo completo con datos ASSUMED, sin archivos de salida por defecto:
setupProject; addpath('app','examples');
out = guidedActuationMechanicsExample;
% Opcional: guidedActuationMechanicsExample('ruta-nueva.mat'); % no sobrescribe
```

[Uso, APIs, ecuaciones y límites](docs/guided-actuation-mechanics.md) ·
[validación real v0.20](docs/v0.20-validation.md) ·
[registro central](docs/development-register.md) · [roadmap](docs/roadmap.md).
La integración conserva RF-01/RF-02/RF-03 y los límites históricos de latencia/
memoria; no promete interfaz continuamente fluida ni historiales arbitrarios.
Direct Acting permanece pendiente. No fabricación/certificación. Auditoría en
otra conversación y gestión de ramas/commits/publicación exclusivamente del usuario.

## Registro histórico v0.19 (no sustituye el estado superior)

Seguimiento actual: [RF-03 — correspondencia operación/resultado](docs/v0.19-rf03-operation-contract.md).
Implementación local y validación focalizada completas:286/286 casos únicos PASS,
48 nuevos; Analyzer0/643. Inventario1954, sin repetir la suite completa. Sin
publicación ni aprobación independiente; preparada para reauditoría de RF-03.

Registro histórico anterior a RF-03: correcciones focalizadas RF-01 (IDs char/string) y RF-02
(protocolo APPEND/REPLACE) en
[informe RF](docs/v0.19-final-rf-corrections.md). Las cifras1872 de la baseline
inferior no representan una repetición completa después de estas correcciones;
155/155 pruebas focalizadas PASS (34 nuevas), Analyzer0/639. El inventario actual
contiene1906 casos; no se afirma una ejecución completa de todos ellos.

**v0.19.0 — Packaging & Physical Feasibility, correcciones V19-F-01/V19-F-02
implementadas y verificadas localmente, pendientes de reauditoría**, sobre la
base publicada v0.18.0 (`ce3ced0`). Rama `feature/v0.19-packaging-feasibility`.
Añade sólidos simplificados explícitos, pares/márgenes, regiones de hardpoints,
evaluación nominal/BUMP almacenado, comparación y persistencia MAT; una sección
Packaging extiende la aplicación existente. No modifica los solvers ni los scores.

```matlab
app = launchFSSuspensionDesigner;
% Ejemplo API con entradas sintéticas explícitas:
setupProject; addpath('examples');
e = packagingFeasibilityExample(false);
```

[Contrato y límites](docs/packaging-physical-feasibility.md) ·
[Informe final y evidencias](docs/v0.19-validation.md) ·
[Correcciones y estado vigente](docs/v0.19-audit-corrections.md) ·
[Interfaz](docs/guided-design-interface.md).
CLEAR_SAMPLED no certifica ausencia de colisiones entre muestras, CAD ni fabricación.
El flujo gráfico completo corregido terminó con PASS:940,8s, guardado y reapertura
exacta de nueve resultados y operación asíncrona157,8s. Pico privado muestreado:
1,94GiB del motor principal y4,13GiB agregados de procesos propios; compromiso
privado no equivale a RAM residente. Son mediciones de ese caso en16GB, no una
garantía para historiales arbitrarios. La referencia anterior a la corrección
(21,8GiB privados del principal/unos20min asíncronos) se conserva en el informe.
Cobertura por37 particiones:1872/1872 identidades únicas PASS;18 ejemplos,
siete benchmarks conservados y Analyzer0/638. Inspección Desktop real realizada;
el cierre manual final no obtuvo resultado (presupuesto de observación y después
reserva de RAM), separado de los tests de ciclo de vida que sí pasaron.
No se afirma un PASS monolítico ni aprobación de la reauditoría.
La validación/fusión final puede bloquear callbacks: no se garantiza respuesta
continua durante toda la operación (45s medidos antes de RF-03, no cota garantizada).
Usar MATLAB Desktop para la UI, no `-batch`.
**No utilizar para fabricar una suspensión real.** Sin commits ni publicación v0.19.

## Historia v0.18 (registro de la implementación original)

**v0.18.0 implementada localmente — pendiente de auditoría independiente**, sobre la
publicación correctiva estable **v0.17.1** (código auditado `f14ed1e`). MATLAB
R2026b / Windows 11. App Designer nativo de texto `.m` + `.xml`, con controlador
y vista separados del núcleo. Desde esta carpeta:

```matlab
app = launchFSSuspensionDesigner;
% Editar el shell auténtico:
appdesigner(fullfile(pwd,'app','FSSuspensionDesigner.m'));
```

Project → Vehicle → 28 decisiones → geometría/3D → BUMP → targets HARD/SOFT →
síntesis de esquina/FRONT → comparación → MAT. Iniciar un worker de procesos
desde Project mantiene las operaciones largas fuera del hilo gráfico; la búsqueda
nativa sigue secuencial. Sin PCT, seleccionar explícitamente el modo síncrono.
No se infieren inputs ni targets óptimos. Aplicar borradores antes de guardar.

[Guía de uso](docs/guided-design-interface.md) ·
[Validación v0.18 y límites](docs/v0.18-validation.md).
Validación R2026b: los1701 tests históricos no fallaron en la ejecución completa;
los40 nuevos pasan tras las correcciones de UI, en una ejecución separada.
No se presenta como1741/1741 PASS monolítico. También17 ejemplos, siete benchmarks,
Analyzer0/580 y dependencias sin ciclos. Véanse incidencias y tiempos en el informe.
El shell es editable en Design View; el layout dinámico se edita en `View.m`.
Sin commits, merges, tags ni releases. Las secciones siguientes son históricas.
**No utilizar esta aplicación para fabricar una suspensión real.**

## Historia v0.17

**v0.17 — Concept-to-Seed & Parametric Suspension Geometry** construye corners
FL/FR/RL/RR o un par FRONT explícitamente simétrico/independiente desde concepto
y decisiones geométricas, sin matriz inicial de hardpoints absolutos. Radio
efectivo, orientación, upright y pivotes se declaran; no se infieren desde masa
o radio descargado. Readiness, validez nominal y BUMP muestreado son independientes.

```matlab
setupProject;
r = runProjectTests;
addpath("examples", "tests");
example = conceptToSeedExample(false);
report = verifyV17;
```

[Parámetros y APIs](docs/concept-to-seed.md) ·
[Validación e inventario](docs/v0.17-validation.md).
Suite global ejecutada monolíticamente: **1701/1701 PASS** (1564 históricos +137
nuevos), Failed0/Incomplete0. El informe distingue los tests de la verificación
de ejemplos, perfiles y costes.
**17/17 ejemplos**, **Analyzer0/559 archivos MATLAB**, grafo de llamadas entre
módulos acíclico y perfiles sin nuevos solves físicos ocultos. Las medianas de
asociación/persistencia incluyen su validación; consultar sus costes en el informe.
MATLAB R2025b y Optimization Toolbox donde lo exige la cinemática histórica.
No App Designer, targets óptimos, nueva dinámica/neumáticos, CAD, rules ni Adams.
**No usar para fabricar una suspensión real.** Sin commits/merge/tag/release/v0.18.

## Historia v0.16

**v0.16 — Vehicle Concept & Engineering Project Workflow** añade proyectos
conceptuales incompletos, incertidumbres y procedencia explícitas, derivaciones
v0.9, escenarios, readiness sin solves, ejecución delegada de análisis y de las
cuatro síntesis v0.12–v0.15, revisiones selectivas y persistencia MAT validada.
No genera seeds ni targets óptimos desde masas/dimensiones. Núcleo MATLAB
R2025b independiente de UI; Optimization Toolbox sólo donde lo requiere la
cinemática histórica. SI y +X atrás/+Y derecha/+Z arriba sin cambios.

```matlab
setupProject;
r = runProjectTests;
addpath("examples", "tests");
example = vehicleConceptProjectExample(false);
report = verifyV16;
```

[Contrato y APIs](docs/vehicle-concept-project-workflow.md) ·
[Informe de validación e inventario](docs/v0.16-validation.md).
Baseline confirmada: 1391/1391 PASS; 15 ejemplos, Analyzer 0/465 y DAG acíclico.
Suite global v0.16 tras V16-F-01: **1564/1564 PASS** (1516 previos+48 nuevos), Failed0,
Incomplete0. Consultar el informe para ejemplos, perfiles y costes. READY significa inputs
estructurales disponibles, no convergencia ni certificación. **No utilizar los
resultados para fabricar una suspensión real**. Sin App Designer, nuevos modelos
dinámicos/neumáticos/rules/Adams, optimizador global ni v0.17. Sin commits,
merges, tags o releases en esta tarea. Las secciones siguientes son históricas;
los verificadores con versión fija se ejecutan en su checkout correspondiente.
Validación final tras V16-F-01: **16/16 ejemplos**, **Analyzer0/519**, **DAG15 acíclico**,
readiness sin búsqueda/solves y validadores/MAT sin nuevos solves físicos.

## Historia v0.15

**v0.15 — Actuation Geometry & Motion Ratio Synthesis** permite síntesis de
actuación PUSHROD/PULLROD para una esquina FL/FR/RL/RR con suspensión fija.
Reconstruye anclajes y eje de rocker, ejecuta BUMP y actuación nativos nuevos,
evalúa MR firmado, recorrido, ángulo y mecánica tangente v0.8, y reutiliza el
assessment v0.11 y boundedDirectSearch v0.12. No incorpora otra física.
[Contrato y APIs](docs/actuation-geometry-synthesis.md) ·
[Informe de validación e inventario](docs/v0.15-validation.md).

```matlab
setupProject;
results = runProjectTests;
addpath("examples", "tests");
example = actuationSynthesisExample(true);
report = verifyV15;
```

MATLAB R2025b; Optimization Toolbox para el BUMP histórico, controlador base
MATLAB. Baseline ejecutada:1224/1224 PASS,14 ejemplos,Analyzer0/435,DAG acíclico.
Benchmark ilustrativo ASSUMED: dos coordenadas del anclaje del damper, nueve
muestras de rueda, referencias nativas independientes, score0.231415023063→0
en ocho candidatos. Los límites son declarados, no datos de catálogo.
Validación completa y costes: informe enlazado; verificadores anteriores son
históricos y tienen versión fija. **No utilizar resultados para fabricar una
suspensión real**. Sin DIRECT ACTING, actuación conjunta de eje, colisiones CAD,
dimensionado estructural, nueva hidráulica, UI final, Adams ni óptimo global.
No se inicia v0.16 ni se realizan commits/merges/tags/releases.
Validación final: **1391/1391 tests PASS** (1224 históricos+167 nuevos),
Failed0/Incomplete0; **15/15 ejemplos**, **Analyzer0/465 archivos MATLAB**,
DAG10 acíclico, consumidores sin forward solves ocultos,66 exports PNG.

## Historia v0.14

**v0.14 — Steering Geometry & Ackermann Synthesis** coordina suspensión y
dirección FRONT FL/FR en un único espacio/assessment. Añade XYZ autorizadas de
TIE_ROD_INBOARD/OUTBOARD a los pivotes de trapecios, rack rígido reconstruido,
BUMP bilateral y RACK nativos nuevos, ROLL centrado opcional, fuentes y snapshots
verificables. Reutiliza boundedDirectSearch y el catálogo v0.11, sin otra física.
[Contrato y APIs](docs/steering-geometry-synthesis.md) · [Validación](docs/v0.14-validation.md).

```matlab
setupProject
results = runProjectTests;
addpath("examples", "tests")
example = steeringSynthesisExample(true);
report = verifyV14;
```

Baseline real:1064/1064 PASS,13 ejemplos,Analyzer0/408,DAG acíclico. Benchmark
alcanzable: E3, BUMP3+3, RACK3, score0.441327900783→0. Se presenta además una
comparación separada frente a cero bump steer/Ackermann ideal: mejorar uno
puede empeorar el otro. Pesos/escalas explícitos; datos ASSUMED de verificación,
**no setup FS recomendado**. Rack cero para BUMP/ROLL; rearAxleX y travel limits
obligatorios; no grid simultáneo roll–steering ni collision checking.
Validación final: **1195/1195 tests PASS**,Failed0/Incomplete0 (1064+131),
**14/14 ejemplos**,**Analyzer0/433 .m**,DAG10 acíclico,consumers sin solves
ocultos y46 PNGs dark/light. Inventario, costes y límites en el informe enlazado.
MATLAB R2025b y Optimization Toolbox/fsolve para física; controlador base MATLAB.
**No utilizar resultados para fabricar una suspensión real**. Sin App Designer,
CAD, certificación normativa, Adams, optimización global, commit/merge/tag/release
ni v0.15. Verificadores de versión fija anteriores son históricos; usar verifyV14.

## Historia v0.13

**v0.13 — Axle-Level Suspension Synthesis** amplía la búsqueda a FRONT FL/FR
o REAR RL/RR con dos seeds explícitos, coordenadas inboard de ambos lados y
vínculos de simetría opcionales. Reconstruye ambos modelos, ejecuta BUMP por
corner y ROLL nativo opcional, y usa un único assessment v0.11/controlador v0.12.
Fuentes, HARD/SOFT/calidad, snapshots, fallos, caché, historial, MAT y gráficos
bilaterales permanecen trazables; no se altera ningún solver histórico.
[Contrato y APIs](docs/axle-level-synthesis.md) · [Validación](docs/v0.13-validation.md).

```matlab
setupProject
results = runProjectTests;
addpath("examples", "tests")
example = axleSuspensionSynthesisExample(true);
report = verifyV13;
```

Baseline v0.12:904/904 PASS,12 ejemplos,Analyzer0/378,DAG acíclico. El benchmark
v0.13 alcanzable modifica ambas esquinas: E7, BUMP7+7, ROLL7, score conjunto
0.086073119596→0. Son datos ASSUMED de software, **no targets ni un setup Formula
Student recomendado**. BUMP/ROLL mantienen Optimization Toolbox/fsolve;
controller base MATLAB. Validación final y límites en el informe enlazado.
Validación final R2025b: **1064/1064 tests PASS** (904 históricos+160 nuevos),
Failed=0, Incomplete=0; **13/13 ejemplos**, **Analyzer0/408 .m**, DAG10 acíclico.
Perfiles del evaluador/validators/reporting sin nuevos solves físicos.
Desarrollo experimental: **no utilizar resultados para fabricar una suspensión
real**. Sin UI, CAD, certificación normativa, Adams ni optimización global.
El verificador verifyV13 corresponde al tag v0.13.0; las secciones siguientes
conservan entregas anteriores.

## Historia v0.12

**v0.12 — Inverse Suspension Synthesis** incorpora búsqueda local acotada y
determinista sobre coordenadas XYZ de cuatro anclajes UCA/LCA inboard de una
esquina. Reconstruye geometrías, ejecuta BUMP real y evalúa camber, toe,
bump steer, caster y KPI con v0.11. Conserva candidatos, fallos, HARD/SOFT,
calidad, cobertura y trazabilidad, sin prometer óptimo global.
[Contrato y APIs](docs/inverse-suspension-synthesis.md) ·
[Validación, inventario y límites](docs/v0.12-validation.md).

Validación R2025b tras F-04: **904/904 tests** (858 previos +46 regresiones),
**12/12 ejemplos**, **0 incidencias /378 archivos MATLAB**, DAG acíclico.
Caso físico alcanzable: siete geometrías/sweeps nuevos y score0.101722096→0
con HARD muestreados satisfechos. Sin modificar ecuaciones/solvers históricos.
[Correcciones, evidencia e inventario](docs/v0.12-audit-corrections.md): opciones
BUMP ligadas a la ejecución, fallos físicos conservados y reporting single/sin
elegibles. MAT anteriores sin snapshot de ejecución deben regenerarse.
Los links UCA/LCA nulos se conservan como intentos geométricos inválidos sin BUMP,
sin score ni geometría ficticia; errores desconocidos siguen relanzándose.

```matlab
setupProject
results = runProjectTests;
addpath("examples", "tests")
example = inverseSuspensionSynthesisExample(true);
report = verifyV12Audit;
```

El ejemplo ASSUMED alcanza curvas procedentes de otra geometría conocida,
no targets recomendados de Formula Student. Búsqueda genérica sin toolbox
obligatoria; BUMP conserva su dependencia histórica de Optimization Toolbox.
Seed obligatorio es una limitación temporal. Sin UI, CAD, reglas, Adams ni
optimización global/multiobjetivo. Los verificadores con versión fijada,
incluido verifyV11, son históricos; para el checkout actual usar **verifyV12Audit**
(incluye verifyV12).
Las cifras/secciones siguientes describen sus milestones históricas.

**v0.11 — Design Requirements, Targets & Evaluation** añade especificaciones
progresivas sin geometría, parámetros con conocimiento/provenance, variables
con bounds pendientes, targets escalares/curvas, restricciones nominales de
hardpoints y evaluación de 23 métricas existentes. Conserva errores, cobertura,
gaps y HARD/SOFT; compara candidatos sin ganador automático ni optimizador.
[Contrato y APIs](docs/design-requirements-target-evaluation.md) ·
[Informe de validación e inventario](docs/v0.11-validation.md).

Validación real MATLAB R2025b: **605/605 tests** (471 históricos + 134 nuevos),
**11/11 ejemplos**, **0 incidencias de Code Analyzer / 326 archivos MATLAB**.
Perfil del evaluador sin nuevos solves; solvers históricos intactos.

```matlab
setupProject
results = runProjectTests;
addpath("examples", "tests")
example = designTargetEvaluationExample(true);
report = verifyV11;
```

Los valores del ejemplo son hipótesis ilustrativas, no targets recomendados.
Las comparaciones son muestreadas: no certifican recorrido continuo, seguridad,
normativa, packaging ni rendimiento. UI, optimización y Adams siguen futuros.
Las secciones siguientes conservan la historia de milestones anteriores.

**v0.10 — Coupled Chassis Pose & Global Static Equilibrium** añade pose rígida
heave/pitch/roll y cuatro wheel travels acoplados por una única energía,
muelles v0.8 y neumáticos verticales unilaterales opcionales con datos explícitos.
Incluye paths 3D validados, solve escalado/multistart, wheel lift, balances world,
estabilidad local condicionada por fiabilidad y validadores por reconstrucción.
No es dinámica ni un sustituto de Adams. [Contrato v0.10](docs/global-static-equilibrium.md).

```matlab
setupProject
results = runProjectTests;
addpath("examples", "tests")
example = globalStaticEquilibriumExample(true);
% verifyV10 es un verificador histórico ligado a la versión 0.10.0.
% Para el checkout actual, ejecutar verifyV11 (arriba).
```

La descripción siguiente conserva las capacidades históricas v0.1–v0.9.
Tras F-01 de selección global, la baseline real al iniciar v0.11 fue **471/471**.

Validación v0.10 en MATLAB R2025b: **444/444 tests** (393 históricos + 51 nuevos),
**10/10 ejemplos**, **0 incidencias de Code Analyzer en 269 archivos**.
Archivos, benchmarks, rendimiento y limitaciones en el
[informe de entrega v0.10](docs/v0.10-validation.md).

**v0.9 — Vehicle Parameters, Static Loads & Corner Equilibrium** conserva v0.1–v0.8 e
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
- coilover ideal opcional por esquina, muelle lineal de compresión, precarga,
  geometría de asientos, descarga y energía almacenada;
- damper pasivo lineal asimétrico o tabulado, con branches por velocidad axial;
- resistencia generalizada firmada en rueda y wheel rate tangente completo
  `k*MR^2 + Fs*dMR/dz`, incluidos diagnósticos de rigidez tangente negativa;
- límites explícitos de longitud/solid height, derivadas condicionadas,
  validación de fuentes y nueve vistas mecánicas agrupadas.

v0.9 añade masas operativas y composición de CG, carga de ejes, familia
indeterminada de cuatro normales, cierre explícito por medidas/crossweight/
simetría asumida, bookkeeping sprung/unsprung y equilibrio LOCAL sobre un
path validado. No publica cuatro corner weights únicos sin cuarta condición.
v0.9 por sí sola no calcula equilibrio global de chasis, heave/pitch/roll acoplados, dinámica,
ARB, anti geometry, neumáticos de fuerzas, optimización, ride frequency ni
damping ratio. Recorrido local de equilibrio no equivale a ride height real.

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

Los contratos de muelle/amortiguador usan schema `0.8.0`; no se modifican
los schemas históricos ni los solvers. Su identity incluye la asociación
con actuación y todos los parámetros físicos, pero no metadata.

## Uso mecánico v0.8

```matlab
setupProject
results = runProjectTests;
addpath("examples")
e = springDamperWheelRateExample(true);

% El ejemplo devuelve modelos y fuentes válidos, no un setup recomendado.
response = fsd.analysis.analyzeSpringDamperSweep( ...
    e.model, e.actuation, e.actuationSweep, e.actuationAnalysis, 100, "mm/s");
% Un estado individual sólo proporciona métricas axiales; no inventa MR.
nominal = e.nominal;
```

Inputs del modelo: `configuration="COILOVER"`, `spring.modelType`, `rate`,
`freeLength`, `preloadCompression`, solid height opcional; damper lineal con
`compressionCoefficient/reboundCoefficient` o tablas `[speed,force_N]`.
Los nombres, unidades, firmas completas y statuses están en
[especificación v0.8](docs/spring-damper-wheel-rate.md).

Roadmap: v0.1–v0.8 conservadas; v0.9 añade vehículo, cargas estáticas y equilibrio local.
ARB y longitudinal anti-geometry siguen siendo milestones futuras.
v0.10 añade equilibrio acoplado de chasis; Adams y App Designer siguen futuros.

## Uso estático de vehículo v0.9

```matlab
addpath("examples")
e = vehicleStaticEquilibriumExample(true);
% M/CG por componentes, familia de cargas, CW explícito y root local estimada.
addpath("tests")
% verifyV09 conserva la comprobación histórica de versión 0.9.0.
report = verifyV10; % verificación actual, incluye los ejemplos históricos
```

Gravity es entrada obligatoria. Cargas en N; kg_equivalent usa esa gravedad.
Datos desconocidos permanecen NaN. Contratos, APIs, modos y limitaciones en
[Vehicle Parameters & Static Load Equilibrium](docs/vehicle-static-equilibrium.md).
Validación tras correcciones de auditoría: **393/393 tests** (368 anteriores +
25 nuevos), **9/9 ejemplos**, **0 incidencias de Code Analyzer / 238 archivos
MATLAB**. Archivos, benchmarks, rendimiento y
limitaciones en el [informe de entrega v0.9](docs/v0.9-validation.md).

Para verificar los ocho ejemplos, Code Analyzer y rendimiento:

```matlab
addpath("tests")
report = verifyV08;
```

## Aviso

**Software en desarrollo. Las geometrías de ejemplo no son targets de Formula Student ni deben utilizarse para fabricar o declarar segura una suspensión real.**
