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
