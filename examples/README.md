# Examples

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
