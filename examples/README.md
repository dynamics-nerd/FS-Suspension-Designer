# Examples

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
