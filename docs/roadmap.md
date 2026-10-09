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

Estado: **implementada**.

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

## v0.5 — Steering Geometry, Rack Kinematics, Scrub Radius, Mechanical Trail & Ackermann

Estado: **implementada**.

Incluye:

- `SteeringSystemGeometry` exclusivamente para `FRONT`, con identity propia y
  referencia mínima `rearAxleX`;
- rack rígido definido por los inner tie-rod joints reales, con eje oblicuo
  permitido y travel en m/mm;
- núcleo de esquina generalizado con tie-rod inboard prescrito, reutilizado
  por bump y steering sin duplicar el solver;
- wheel travel simétrico o `[left,right]` combinado con rack travel;
- continuation en dos etapas: wheel travel con rack cero y después rack a
  wheel travel constante;
- road-wheel heading/angle, deflexión desde estático y steering inducido por
  rack, separados de toe y bump steer;
- intersección eje de dirección–plano de contacto, scrub radius y mechanical
  trail con signos globales documentados;
- Ackermann por ICR sobre la línea del eje trasero, compatible con static toe,
  wheel stagger y contactos reales, con tratamiento proyectivo near-straight;
- rack sweeps, análisis, visualización 3D y curvas en mm/grados;
- propagación explícita de fallos e integridad system/result/sweep.

No incluye steering wheel/column, pinion ratio, fuerzas de dirección,
compliance, pneumatic trail, body roll, full vehicle, actuación, packaging,
rules, neumáticos de fuerzas, dinámica, optimización, Adams ni App Designer.

### Criterios de aceptación v0.5

1. Rack cero reproduce `solveBump` para el mismo wheel travel.
2. Ambos inner joints reciben la misma traslación sobre el eje FL→FR y
   conservan su separación, incluso con rack oblicuo.
3. El solver combinado cierra cuatro links UCA/LCA y tie rod, preserva upright,
   wheel attachment, travel, wheel axis y contacto.
4. Heading recto es `[-1,0,0]`; ángulo positivo apunta a `+Y`; las diferencias
   son robustas en ±pi.
5. Scrub/trail reproducen casos analíticos cero, positivos, negativos y espejo.
6. Ackermann ideal produce ICR común/error cero; parallel steering y casos a
   ambos lados del ideal producen error con signo documentado.
7. Rack cero con static toe no se publica como giro Ackermann y conserva las
   curvas toe/bump-steer v0.3.
8. Round trips, giros espejo, wheel stagger, bump+steering y rack imposible
   tienen tests independientes.
9. Ningún análisis bilateral se publica válido con una esquina fallida.
10. Pasan la suite histórica y nueva, todos los ejemplos, Code Analyzer,
    comprobación de dependencias y `git diff --check`.

## v0.6 — Body Roll & Asymmetric Axle Kinematics

Estado: **implementada**.

Incluye recorrido de eje `[zLeft,zRight]`, compatibilidad de heave, cierre de
body roll contra contactos geométricos reales, continuation heave-first y
roll-second, sweep ordenado, carretera normalizada YZ, camber relativo al
chasis/carretera, FVIC, roll center, altura perpendicular a carretera, dos
definiciones de track, migración, visualización y ejemplo de integración con
steering mediante wheel travels reutilizados.

No incluye cierre simultáneo steering+roll, Ackermann road-aligned, modelo de
vehículo completo, pitch, fuerzas, ARB, muelles, actuation, anti geometry,
dinámica, neumático de fuerzas, optimización, packaging, rules, Adams o UI.

### Criterios de aceptación v0.6

1. Pares arbitrarios de wheel travel funcionan en ejes FRONT y REAR, y el caso
   igual reproduce la API histórica de heave.
2. El roll solve satisface `nRoad dot (CR-CL)=0` con contactos reales y
   `h=(zLeft+zRight)/2`.
3. El solver usa una raíz escalar bracketed y continuation sin reordenar sweeps.
4. Road lines tienen normal unitaria determinista; contactos coincidentes o
   invertidos y raíces no bracketed conservan status específico.
5. Camber chassis/road, RC y tracks mantienen signos, unidades e identities.
6. La altura road-relative es distancia firmada y no sustituye la altura
   histórica cuando los contactos tienen distinto Z.
7. Benchmark analítico, residual, signos, round trips, simetría, asimetría,
   fallos e integración básica con steering quedan probados.
8. Suite histórica y nueva, ejemplos, Code Analyzer y diff check pasan.

## v0.7 — Actuation Geometry & Kinematics

Estado: **implementada**.

Incluye modelo opcional por esquina, PUSHROD/PULLROD, attachments UPRIGHT/UCA/LCA,
rocker YZ/XZ/CUSTOM, eje 3D canonicalizado, closure analítico, branch continuation,
damper compression, motion-ratio migration, stroke/range, integración downstream
con bump, asymmetric axle, body roll y steering, visualización e integridad.

No incluye fuerzas, wheel rate completo, ARB, anti geometry, optimización,
packaging, full vehicle, Adams ni App Designer.

### Criterios de aceptación v0.7

1. PUSHROD/PULLROD comparte ecuaciones y conserva identity distinta.
2. UPRIGHT/UCA/LCA preservan todos los invariantes de su rigid body.
3. YZ/XZ/CUSTOM cierran el rod y conservan rigidez del rocker.
4. Roots múltiples continúan localmente; tangencia y no-solution se distinguen.
5. MR usa la definición canónica y diferencias finitas de segundo orden.
6. Sweeps publican stroke/range y no fabrican derivadas cuando la coordenada es
   inadecuada.
7. Steering, asymmetric travel y body roll se consumen sin repetir solves.
8. Suite histórica/nueva, ejemplos, Code Analyzer y diff check pasan.

## Futuro — Anti-Roll Bar Design

La futura decisión de producto se expresará como
`antiRollBarStrategy = INTEGRATED | POST_DESIGN | DISABLED`:

- `INTEGRATED`: existencia, geometría, stiffness y contribución front/rear del
  ARB forman parte de la optimización conjunta desde el principio.
- `POST_DESIGN`: primero se diseña con ARB desactivada y después se diseña y
  configura para modificar roll stiffness, distribución front/rear y balance.
- `DISABLED`: el vehículo se diseña y permanece sin ARB.

La milestone deberá cubrir torsion bar, arms/blades, drop links, ARB wheel
rate, roll-mode stiffness, distribución front/rear y los tres workflows. No se
mezcla con el rocker del damper. Una ARB puede modificar load-transfer y roll
stiffness distribution, pero no se prometerá corregir understeer/oversteer sin
neumáticos, load sensitivity, fuerzas, aero y modelo de vehículo.

## Futuro — Longitudinal Anti-Geometry

Milestone no iniciada. Deberá tratar por separado y con terminología aprobada:

- anti-dive;
- anti-lift / anti-rise según condición y eje;
- anti-squat.

Como mínimo requerirá geometría side-view, wheelbase, posición/altura de CG,
definición del camino de fuerzas, brake-force distribution cuando corresponda
y driven axle/drive-force assumptions cuando corresponda. Antes de implementar
habrá que fijar explícitamente terminología, ecuaciones, signos y definición de
cualquier porcentaje. v0.7 no calcula ninguna de estas magnitudes.

## v0.8 — Spring, Damper & Wheel-Rate Modelling

Estado: **implementada**, pendiente de revisión humana y merge autorizado.

Incluye coilover ideal opcional, muelle lineal de compresión y preload,
separación de asientos, descarga, energía, damping lineal asimétrico y tabulado,
proyección firmada, wheel rate elástico/geometrico/total, límites proporcionados,
derivada directa de MR, integridad, plots, ejemplo y pruebas independientes.

Criterios de aceptación:

1. Benchmarks `c=a*z+b*z^2` y MR constante reproducen fuerza, energía y
   rigidez, con precarga cero/no cero y mallas crecientes/decrecientes.
2. `Fw=dU/dz`; `Kw=dFw/dz`; preload modifica el término geométrico.
3. MR negativo selecciona correctamente la branch axial; ambas potencias
   disipadas coinciden y son no negativas.
4. Unseating, transición, solid height, límites de damper y fuera de tablas
   mantienen statuses explícitos y no inventan leyes de end stops.
5. Gaps, fuentes incorrectas y derivadas no válidas no generan métricas en rueda.
6. Los cuatro corners, asymmetric travel, roll y steering consumen sus
   fuentes sin nuevos solves dentro del análisis mecánico.
7. Suite histórica y nueva, ocho ejemplos, Code Analyzer sin incidencias,
   dependencias acíclicas, perfil de cero solves y diff check pasan.

Fuera de alcance: equilibrio global, cargas neumático/aero, ride frequency,
damping ratio, ARB, resortes no lineales, bump stops, heave/third springs,
torsion springs, hysteresis/thermal, rod forces/fatigue, anti geometry,
optimización, normativa, packaging collisions, Adams y App Designer.

La estrategia ARB `INTEGRATED | POST_DESIGN | DISABLED` y la milestone
longitudinal anti-dive, anti-lift/anti-rise y anti-squat anteriores se conservan.
NM-001 y NM-002 permanecen resueltas. v0.9 se describe a continuación.

## v0.9 — Vehicle Parameters, Static Loads & Corner Equilibrium

Implementada: masas operativas, CG compuesto, dimensiones/gravedad/contactos,
cargas de eje y familia de cuatro contactos, closure measured/CW/ASSUMED,
bookkeeping sprung/unsprung, comparaciones y equilibrio local sobre path v0.8.
Criterios: indeterminación sin cuarta condición explícita, desconocidos NaN,
balances/momento/no negatividad, roots y selección no arbitrarias, F-01 intacto,
327 históricos + tests nuevos, nueve ejemplos, Analyzer cero y DAG conservado.
No incluye equilibrio simultáneo de chasis, dinámica, ARB, anti, aero, tires,
optimización, Adams ni UI. Root interpolada no es ride height ni pose resuelta.

## v0.10 — Coupled Chassis Pose & Global Static Equilibrium

Implementada como modelo reducido SAMPLED_PATH_APPROXIMATION: siete DOF,
pose rígida, cuatro paths 3D de bump fixed-inboard, springs v0.8, vertical tire
unilateral con inputs explícitos, CG sprung/unsprung móviles, U canónica y
solve global escalado/multistart. Eval/solve separados, contacto/wheel lift,
balances world, CW emergente, estabilidad condicionada por calidad, identidades,
validadores, referencias de altura definidas, plots/ejemplo/benchmarks.

Criterios: benchmark200kg/g10 reproduce h=-5mm, N500/corner; gradient de U
independiente; momentos actuales; tres contactos sin tensión; múltiples roots
y estabilidad diferenciadas; gaps/MR/c2/límites indisponibles sin falsos outputs;
393 históricos + tests nuevos, diez ejemplos, Analyzer0/DAG/perfil/diff check.
Evidencia en [informe v0.10](v0.10-validation.md). Pendiente revisión humana.
Limitación de integración: el contrato de sweep existente sólo fija inboard/rack0;
no se afirma fixed-rack no nulo ni multibody continuo exacto.
ARB INTEGRATED/POST_DESIGN/DISABLED y longitudinal anti geometry se conservan.
Sin dinámica/aero/ARB/rules/Tilt/UI/Adams; no se inicia v0.11.
