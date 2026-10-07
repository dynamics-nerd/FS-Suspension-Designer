# Testing strategy

> Engineering change → Unit test → Known case → Validation → Merge

```matlab
results = runProjectTests;
```

La suite cubre:

- foundation y documentación;
- construcción estática m/mm, IDs, procedencia, reflexión, MAT y plot;
- tie rod y upright no collinear;
- rotation vector, ortonormalidad y transformación rígida;
- estado estático exacto;
- bump y rebound solicitados;
- conservación de cuatro links UCA/LCA y tie rod;
- rigidez interna del upright y wheel attachment;
- norma del wheel axis;
- simetría FL/FR y signo de camber;
- sweep, continuidad y round trip a cero;
- fallo explícito para travel imposible;
- plot estático/desplazado.
- toe analítico con toe-in/out y simetría por lado;
- aislamiento de toe frente a camber;
- steering axis LBJ→UBJ, caster XZ y kingpin inclination YZ;
- toe estático no nulo conservado y bump steer cero en traslación pura;
- fixture con bump steer de signo conocido, continuidad y reflexión FL/FR;
- correspondencia exacta sweep/análisis y propagación `NaN` de fallos;
- cinco curvas de análisis y unidades de presentación.
- identidad geometry/result y rechazo de diferencias de hardpoint de `1e-6 m`;
- invariantes `converged/status` y rechazo de statuses desconocidos;
- contrato completo de `SuspensionState`, payload fallido y redundancias;
- corner IDs char multirrenglón rechazados en APIs canónicas y wrapper legado;
- bump steer referenciado a estático en sweeps positivos, negativos y discontinuos sin cero.
- identity falsificada con offsets de `1e-6 m` en pivotes UCA, LCA y tie rod;
- rechazo de sweep con identity falsificada en cabecera y resultados;
- constraints físicos del payload contra la geometry identity declarada;
- `attempted` correcto para CONVERGED, NO_CONVERGENCE y NOT_ATTEMPTED;
- secuencia real continuation: convergidos, fallo y targets posteriores no intentados;
- equivalencia de camber entre primitiva `geometry` y wrappers públicos.

## Benchmark independiente

El fixture `TestBumpKinematics.benchmarkGeometry` usa brazos iguales con ejes paralelos y tie rod compatible. Todos los puntos rígidos se trasladan sobre un arco de radio `0.3 m` sin rotación. Para travel `w`, el expected value es:

```text
deltaY = 0.3 - sqrt(0.3^2 - w^2)
R = I
camber = 0
```

La expectativa se deriva del círculo, no de la salida del solver.

En v0.3 se asigna toe estático conocido al mismo fixture. Como `R=I`, el wheel axis no rota: toe permanece constante y bump steer debe ser cero independientemente de la implementación de análisis.

## Fixture independiente de bump steer

Se baja `TIE_ROD_INBOARD` 50 mm respecto a `TIE_ROD_OUTBOARD`, manteniendo los brazos del benchmark. Al desplazarse el upright, la longitud fija del tie rod obliga una rotación: el fixture produce toe-in en rebound y toe-out en bump con la convención X hacia atrás. Los tests comprueban signo, cero estático, continuidad y reflexión lateral; no generan el expected value llamando de nuevo a la función probada.

Los tolerances angulares de los tests analíticos son `1e-14 rad`. Las comparaciones que atraviesan `fsolve` usan `2e-8 rad`, coherentes con las tolerancias existentes del benchmark v0.2 y no representan tolerancias de fabricación.

Los tests sin cero verifican directamente `bumpSteer=toe-staticToe`, además de comprobar que ni el primer target ni el target más próximo a cero se convierten en referencia implícita.

## Cobertura v0.4

- contratos FRONT `FL/FR` y REAR `RL/RR`, orden lateral e identity de eje;
- wheel stagger y geometría deliberadamente asimétrica;
- restricción cinemática desde `u × (B-Paxis)` y reducción al método clásico;
- ejes interiores 3D oblicuos, pivot order y regresión contra el antiguo
  atajo de seccionar el plano del brazo;
- velocidad de UBJ/LBJ alrededor de `20 mm` por diferencia central del solver
  (`h=1e-5 m`) y FVIC independiente obtenido resolviendo las dos restricciones
  de velocidad;
- benchmark exacto simétrico: IC `±0.1 m`, `Z=0.25 m`, RC `Z=13/44 m`;
- benchmark asimétrico: `Y_RC=-247/3020 m`, sin forzar centerline;
- rueda circular ideal, radio, ortogonalidad y rechazo de datum incompatible;
- IC infinito, coincidente y restricciones degeneradas;
- intersecciones homogéneas, casi paralelas y conditioning explícito;
- líneas de construcción con IC infinito, incluidos RC finito y RC infinito;
- composición de heave, continuation bilateral y simetría de `Y_RC`;
- rechazo de resultados intercambiados, axle identities mezcladas y análisis
  de puntos sin convergencia bilateral, con payload fallido completamente
  inválido y sin datos dinámicos clonados del estado estático;
- plots de vista frontal y migración en unidades de presentación.

## Cobertura v0.5

- construcción FRONT, identity, unidades m/mm, rack oblicuo y rechazo de eje
  trasero o joints coincidentes;
- compatibilidad exacta `rack=0` con `solveBump` para distintos wheel travels;
- traslación rígida de ambos inner joints y conservación de separación;
- cierre combinado con wheel travel asimétrico y rack travel;
- round trips `0 -> +rack -> 0` y `0 -> -rack -> 0`;
- heading/road-wheel angle analíticos y wrapping alrededor de ±pi;
- intersección de steering axis finita, paralela y condicionamiento;
- scrub y mechanical trail cero, positivos, negativos y espejo FL/FR;
- Ackermann clásico ideal con ICR común, parallel steering, signo del error a
  ambos lados del ideal, near-straight, static toe y wheel stagger;
- curvas toe/bump-steer preservadas con rack cero;
- giros espejo para racks opuestos, contactos y métricas laterales;
- rack imposible, payload `NaN`, Ackermann inválido e integrity mismatch;
- fallo unilateral FL/FR: invalida ambos lados del análisis, conserva
  diagnostics individuales y propaga `NaN` en sweeps sin reutilizar datos;
- rechazo de un rack sweep manipulado antes de entrar al core privado;
- sweep ordenado, análisis agregado y cinco visualizaciones en unidades de
  presentación.

Los expected de heading, scrub, trail e ICR se obtienen mediante geometría
analítica y relaciones independientes, no realimentando outputs del solver.

`TestV04GoldenRegression` añade referencias numéricas generadas con MATLAB
R2025b desde el commit v0.4.0
`6cf64c5c0a23d4c4deb396681a8dfdf2d2f4443d`, anterior a la generalización del
solver. Cubre FL a 0/+20/-20 mm, FR a +20/-20 mm y una geometría 3D a +12 mm;
compara UBJ, LBJ, tie-rod outboard, Wheel Center, wheel axis, camber y toe sin
llamar a `solveBump` actual como expected.

## Cobertura v0.6

- pares asimétricos `[+15,-10]`, `[-12,+8]`, `[+20,+5] mm`, FRONT/REAR,
  constraints por lado, sweep ordenado e identity;
- regresión `solveAxleTravel([z,z])` contra `solveAxleHeave`;
- base ortonormal de carretera, líneas normalizadas, distancia firmada y
  degeneración/inversión de contactos;
- benchmark exacto de traslación circular con Delta derivado en
  `docs/equations.md`, independiente de `fzero`;
- residual de cierre para roll positivo/negativo, heave cero/no cero,
  equivalencia deg/rad y signo `phi>0 => zLeft>0,zRight<0` en fixture espejo;
- round trips pasando por cero con heave cero/no cero y paridades espejo de
  travel, camber, toe, RC y tracks;
- camber road-relative manual para FL/FR con wheel axes verticales;
- altura RC road-relative por evaluación manual de `aY+bZ+c` y conservación
  explícita del status histórico `CONTACT_LEVEL_MISMATCH`;
- root no bracketed, heave imposible, payloads NaN, targets/identities
  manipulados e incompatibilidad entre axles;
- integración con `solveSteering` usando wheel travels de roll y rack no cero;
- plots de front view inclinada y curvas de camber, RC y track.
- regresión near-limit a `h=0.197541687 m`, `phi=0.1 deg` y
  `Delta≈0.000526305367 m`;
- bracket normal, endpoint inválido unilateral en cada lado, conservación del
  último dominio válido, raíz no bracketed, dominio insuficiente y root exacta
  en el centro sin `fzero`;
- sweep `[0,4,0] deg` con `CONVERGED/ROOT_NOT_BRACKETED/NOT_ATTEMPTED`, status
  cinemático preservado, status de análisis separado y todos los agregados
  fallidos en `NaN`.
