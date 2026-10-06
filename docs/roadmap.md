# Roadmap

## v0.1 — Static Double Wishbone Geometry

Completada y conservada: construcción, validación, consulta, reflexión, geometría elemental, plot y MAT. El schema se amplía en v0.2 con tie rod porque la pose del upright no podía cerrarse físicamente con solo UBJ/LBJ.

## v0.2 — Bump Kinematics

Estado: **implementada**.

Incluye:

- tie rod rígido con inboard fijo;
- upright rígido no degenerado;
- wheel travel individual en m/mm;
- pose con translation + rotation vector;
- cinco constraints de cierre resueltos con `fsolve`;
- continuation desde el estado estático y entre targets de sweep;
- transformación rígida de Wheel Center, Contact Patch y wheel axis;
- camber absoluto con signo común FL/FR;
- manejo explícito de no convergencia;
- comparación 3D y curva Camber(WheelTravel);
- benchmark analítico y tests de constraints, simetría, continuidad y fallo.

No incluye toe como output, bump steer, steering rack, caster, KPI, scrub, trail, instant centers, roll center, roll/pitch/heave de vehículo, actuación, packaging, reglas, neumáticos, dinámica, optimización, Adams ni App Designer.

## v0.3 — Single-Corner Kinematic Analysis

Estado: **implementada**.

Incluye:

- separación explícita entre estados físicos de `fsd.kinematics` e interpretación en `fsd.analysis`;
- camber canónico con wrapper compatible en `fsd.kinematics`;
- toe absoluto, positivo toe-in y aislado de camber;
- bump steer relativo al toe estático;
- steering axis unitario LBJ→UBJ;
- caster y kingpin inclination con signos simétricos FL/FR;
- análisis por estado y por sweep sin interpolación de fallos;
- cinco curvas en mm/grados como presentación;
- benchmarks analíticos, fixture con bump steer y tests de simetría;
- medición separada del tiempo de solver y del análisis derivado.

No incluye:

- steering input, desplazamiento de rack ni Ackermann;
- scrub radius, mechanical trail o pneumatic trail;
- instant centers o roll center;
- modelo de eje completo, roll, pitch o heave;
- actuación, packaging, reglas, neumáticos, dinámica u optimización;
- Adams Car o App Designer.
- gradientes opcionales por diferencias finitas; se difieren hasta existir un caso de optimización aprobado.

### Criterios de aceptación v0.3

1. Todas las métricas documentadas usan m/rad internamente y signos idénticos bajo reflexión FL↔FR.
2. Toe nominal es cero, toe-in positivo y la componente vertical del wheel axis no altera toe.
3. El benchmark de traslación conserva toe y produce bump steer cero.
4. Un fixture independiente genera bump steer continuo con signo esperado en bump/rebound.
5. Los estados fallidos conservan posición, status y causa con métricas `NaN`.
6. Solver y análisis publican tiempos separados; las cinco curvas se representan sin recalcular cinemática.
7. Pasan todos los tests previos y nuevos, ejemplos afectados, Code Analyzer y `git diff --check`.

## v0.4 — Axle Geometry, Front-View Instant Centers & Roll Center

Estado: **implementada, pendiente de auditoría independiente**.

Incluye composición FRONT/REAR asimétrica, identity de eje, restricciones
frontales derivadas de la velocidad instantánea 3D, FVIC proyectivo con
statuses explícitos, rueda circular ideal, roll center estático, altura
respecto a contacto común, heave simétrico, migración, visualizaciones y
benchmarks analíticos.

No incluye body roll, roll axis de vehículo completo, steering, scrub/trail,
anti geometry, actuación, neumático de fuerzas, dinámica, optimización, Adams
ni App Designer.

### Criterios de aceptación v0.4

1. Solo se aceptan pares FL/FR o RL/RR correctamente ordenados, sin exigir
   simetría.
2. La formulación cinemática 3D se reduce al método frontal clásico con ejes
   interiores longitudinales y se verifica con ejes oblicuos y diferencias
   finitas del solver.
3. Casos finito, infinito, coincidente y degenerado se distinguen sin puntos
   ficticios; una intersección casi paralela expone conditioning.
4. Los benchmarks simétrico y asimétrico reproducen valores derivados a mano.
5. El contacto dinámico usa wheel axis actual y radio geométrico constante.
6. Heave y sweep conservan identities y convergencia independiente por lado.
7. Simetría reflejada mantiene `Y_RC=0` durante el sweep.
8. Pasan tests anteriores y nuevos, ejemplos, Code Analyzer y diff check.
9. Un IC infinito puede construir una línea contacto–IC y obtener un roll
   center finito cuando la geometría del eje lo permite.
10. Los puntos fallidos del sweep no contienen una copia de datos dinámicos
    pertenecientes al estado estático.

## Milestone siguiente

No se define ni se inicia v0.5 en este cambio.
