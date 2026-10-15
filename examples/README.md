# Examples

## v0.17 — Concept to Seed

`setupProject; addpath("examples"); out=conceptToSeedExample(false);`.
Concepto parcial y decisiones ausentes -> definición completa explícita ->
FRONT simétrico -> BUMP real -> síntesis nativa desde geometría generada ->
registro/revisiones/MAT. parametricSeedInputs declara dimensiones/offsets/líneas,
sin matriz inicial de hardpoints. Datos/targets ilustrativos ASSUMED, no setup FS.
Steering es acción opcional explícita; no generación de actuación ni prestaciones.

## v0.15

`actuationSynthesisSeed(architecture,corner)` proporciona geometrías ilustrativas
PUSHROD/PULLROD distintas, reflejadas/traducidas para FL/FR/RL/RR, coilover conocido
30000N/m, precarga20mm, damping lineal asimétrico1500/2500Ns/m. Todo ASSUMED.
`actuationSynthesisExample(showPlots)` modifica Y/Z del damper chassis ±10mm,
mantiene X/rocker/rod FIXED, impone box nominal y límite explícito shortening±30mm.
Nueve muestras z=[−20:5:20]mm y velocidad cero prescrita; objetivos MR/travel/Kw
de una referencia nativa desplazada+5mm Y/Z, pesos3/1/1 y escalas .1/.01m/30000N/m.
E8,attempt9/cache1,BUMP8/ACT8/MECH8,score .231415023063→0; la geometría cambia
sin modificar suspensión. Repite seleccionado fuera del coordinador, muestra
PULLROD físico distinto, compara y guarda/revalida MAT. Seis sweeps externos
(referencia/repetición/pull), aparte de los16 del search:22 en todo el ejemplo.
`verifyV15` ejecuta los14 históricos+éste, PNGs/perfiles/Analyzer/DAG/costes.
No datos/setup FS recomendados ni certificación de fabricación.

## v0.14

`steeringSynthesisExample(showPlots)` define dos corners/steering FRONT ASSUMED,
rear line1.6m, dos TRout X [.04,.06]m vinculados, UBJ/inners FIXED/boxes nominales.
Referencia nativa .055m: BUMP steer/toe por lado, toe/headings RACK y Ackermann
en ambos rangos de rack (giro deducido del mecanismo). Pesos diferentes3/1/.5/2,
escalas .01rad y .001rad, tolerancia1e-7rad sólo de verificación. Search E3,
BUMP3+3/RACK3, mejora0.441327900783→0, repetición física independiente y MAT.
Hay seis sweeps externos explícitos (referencia3/repetición3); search cuenta9.
Comparación secundaria ZERO_STEER_TRADEOFF reutiliza evidencia fresca bajo
otra spec explícita; aumentar pickup X mejora bump steer pero empeora Ackermann
ideal. No se sustituye el objetivo de búsqueda ni se proclama ganador Pareto.
`verifyV14` ejecuta los trece ejemplos históricos+éste, PNGs/perfiles/costes y
Analyzer/DAG. No datos/setup FS recomendados ni certificación de fabricación.

## v0.13

`axleSuspensionSynthesisExample(showPlots,useSymmetry)` suministra ambos seeds
FL/FR, cuatro upper inboard Z con +/-10mm, links opcionales, dos UBJ HARD FIXED,
camber/toe BUMP por lado y road camber ROLL a h=0. Targets proceden de una
referencia alcanzable modificada5mm, resuelta aparte con APIs nativas.
Un controller/assessment conjunto busca, retiene candidatos y compara ambos
modelos/curvas; repite físicamente el seleccionado y guarda/revalida MAT.
Default simétrico: E7, BUMP7+7, ROLL7, mejora0.086073119596→0. Datos ASSUMED de
verificación, no setup FS ni óptimo global/certificación continua/fabricación.
`verifyV13` ejecuta los doce ejemplos anteriores y éste (showPlots=false),
después verifica reporting, perfiles, Analyzer/DAG y costes. [Contrato](../docs/axle-level-synthesis.md).

## v0.12

`inverseSuspensionSynthesisExample(showPlots)` define un seed 3D ASSUMED,
dos upper inboard Z FREE con +/-10mm declarados, UBJ FIXED y box nominal,
curvas camber/toe de una referencia alcanzable resuelta aparte y límite HARD
toe ilustrativo. Busca con presupuesto explícito, compara seed/candidato,
imprime todos los intentos físicos con motivo/score, guarda MAT bajo output
y presenta trace/variables/calidad/paso y curvas/targets. Mejora respecto al
seed no implica óptimo global ni setup FS recomendado. verifyV12 ejecuta
los once anteriores y éste: doce ejemplos. Todos aceptan showPlots=false.

## v0.11

`designTargetEvaluationExample(showPlots)` registra KNOWN/RANGE/FIXED/ASSUMED/
FREE y CG desconocido sin rellenar cero, camber curve, toe band, signed MR,
box del UBJ y Ackermann HARD con fuente ausente. Genera explícitamente bump/
actuation/mechanical antes de evaluar, compara dos geometrías, imprime tablas
con errores/unidades/cobertura/missing y dibuja cuatro figuras target/actual/
aceptación/error/violaciones/gaps con ambos IDs. A mejora toe, B mejora camber
pero viola UBJ; no hay ganador. Todos los valores son ilustrativos, no targets
recomendados, ni certificación continua/normativa/packaging/rendimiento.
verifyV11 ejecuta éste y los diez ejemplos históricos. No nuevo módulo/UI.

## v0.10

`globalStaticEquilibriumExample(showPlots)` construye cuatro geometrías y
rockers independientes, paths bump 3D resueltos, springs/dampers v0.8, neumáticos
verticales ASSUMED, vehículo/case y referencias físicas de altura.
Publica h/pitch/roll, travels, normales/CW/contactos/Fs y momentos world.
Tres figuras: pose/road/tire surrogate, cargas/compresiones/residual, energy
slices prescritas (NO re-equilibradas). Sin datos recomendados de Formula Student.
Kt/R0, mu/CG, preload y g son hipótesis ilustrativas, no medidas reales.
Paths se crean antes de solve; no re-solves dentro del análisis energético.
Los nueve ejemplos anteriores permanecen disponibles; verifyV10 ejecuta diez.

## v0.9

vehicleStaticEquilibriumExample(showPlots) enseña masas base/piloto/fuel con
provenance ASSUMED, CG, indeterminación diagonal, closure CW, soporte reducido,
equilibrio local y comparación con vehículo sin piloto. Tres figuras muestran
planta/cargas indeterminadas, distribución cerrada y roots sobre fuerza-travel.
Valores ilustrativos, no recomendaciones de setup. No afirma equilibrio global.

- `staticDoubleWishboneExample`: construcción, consulta, reflexión y plot estático con diez hardpoints.
- `bumpKinematicsExample`: estado cero, bump, rebound, sweep, Camber(WheelTravel) y comparación 3D.
- `singleCornerAnalysisExample`: geometría, sweep, camber, toe, bump steer, caster, kingpin inclination y tiempos separados de solver/análisis.
- `axleRollCenterExample`: eje FL/FR, FVIC, contacto circular ideal, roll
  center estático, heave simétrico, sweep `-30:5:30 mm`, vista frontal y
  curvas de migración.
- `steeringKinematicsExample`: rack delantero, giros en ambos sentidos,
  steering+bump, sweep `-20:2:20 mm`, scrub, mechanical trail, Ackermann,
  visualización 3D y curvas. La referencia trasera demostrativa es ficticia.
- `bodyRollKinematicsExample`: estados de roll cero/positivo/negativo, wheel
  travels resueltos, sweep `-3:0.25:3 deg`, camber chassis/road, migración de
  RC y track, vista frontal inclinada e integración básica con steering. El
  estado steered reutiliza wheel travels pero no re-resuelve el cierre de
  carretera después de girar las ruedas.
- `actuationKinematicsExample`: geometría PUSHROD con rocker YZ, static/bump/
  rebound, sweep, rocker angle, damper compression, MR migration, stroke,
  visualización y un segundo caso PULLROD CUSTOM inclinado.

Todos los hardpoints son ficticios y no constituyen targets ni recomendaciones de Formula Student.

- `springDamperWheelRateExample`: reutiliza geometría/actuación, añade muelle
  con preload, damping asimétrico, velocidades prescritas, wheel rate total
  frente al término elástico, energía, validadores y un segundo modelo con
  límites estrechos. Dos figuras de nueve vistas, no nueve ventanas.
  `springDamperWheelRateExample(false)` omite figuras para validación batch.

Example geometry and mechanical parameters only — not a Formula Student setup recommendation.

## v0.16 Vehicle Concept & Engineering Project Workflow

`vehicleConceptProjectExample(showPlots)` demuestra dos flujos. Primero registra
masas/dimensiones ASSUMED sin CG ni geometría, deriva270kg y guarda un proyecto
parcial con readiness MISSING_DATA. Después incorpora los seeds/spec/targets
EXPLÍCITOS de actuationSynthesisExample, ejecuta BUMP y síntesis de actuación,
obtiene ocho candidatos, valida/asocia resultados y guarda revisiones MAT.
Masa irrelevante permite reutilizar evidencia, sin reetiquetar la ejecución;
opciones relevantes la vuelven STALE. El ejemplo heredado de preparación hace
22 sweeps físicos, separados del presupuesto nuevo:9 BUMP/8 ACT/8 MECH.
No genera una suspensión autónoma desde datos conceptuales ni recomienda MR.
`verifyV16` ejecuta los 15 anteriores y éste, con regresiones v12–v15.
