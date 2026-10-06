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

## Benchmark independiente

El fixture `TestBumpKinematics.benchmarkGeometry` usa brazos iguales con ejes paralelos y tie rod compatible. Todos los puntos rígidos se trasladan sobre un arco de radio `0.3 m` sin rotación. Para travel `w`, el expected value es:

```text
deltaY = 0.3 - sqrt(0.3^2 - w^2)
R = I
camber = 0
```

La expectativa se deriva del círculo, no de la salida del solver.
