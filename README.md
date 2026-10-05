# FS Suspension Designer

Aplicación MATLAB en desarrollo para diseño, síntesis, optimización y validación de suspensiones de Formula Student. El núcleo matemático es independiente de la futura interfaz App Designer y de adaptadores externos.

## Estado actual

**v0.1 — Static Double Wishbone Geometry implementada.** El proyecto representa, valida, consulta, refleja, mide, visualiza y persiste en MAT una esquina double wishbone estática.

No existe solver de movimiento. Tampoco se implementan camber, toe, caster, KPI, steering, roll center, actuación, neumáticos, dinámica, optimización, normativa ni Adams.

## Convención física

- X positivo hacia atrás.
- Y positivo hacia la derecha.
- Z positivo hacia arriba.
- Origen: punto medio entre los contact patches delanteros sobre el suelo nominal.
- Longitud interna: metros; el constructor acepta entrada explícita en `"m"` o `"mm"`.

Consulte [`docs/coordinate-system.md`](docs/coordinate-system.md) antes de crear datos.

## Uso rápido

```matlab
setupProject
results = runProjectTests;

addpath("examples")
exampleResult = staticDoubleWishboneExample(true);
```

Solo `src` es necesario en el path para usar el núcleo. `runProjectTests` restaura el path anterior al terminar.

La API y el schema completos están en [`docs/data-model.md`](docs/data-model.md). El ejemplo usa datos ficticios en milímetros, verifica su conversión a metros, refleja FL→FR y dibuja ambas esquinas.

## Estructura

- `src/+fsd/+model`: construcción, validación, consulta, tolerancias y persistencia MAT.
- `src/+fsd/+geometry`: operaciones estáticas, reflexión y plot 3D.
- `tests`: suite `matlab.unittest` con casos positivos, negativos y analíticos.
- `examples`: demostración reproducible v0.1.
- `docs`: arquitectura, convenciones, schema, ecuaciones y decisiones.
- `app`: reservada para la futura UI; no contiene cálculos.
- `output`: resultados locales generados.

## Roadmap

v0.1 se limita a geometría estática. La siguiente tarea prevista es v0.2 — Bump Kinematics, pero no forma parte de esta versión y sus ecuaciones aún deben especificarse antes de implementarse.

## Aviso

**Software en desarrollo. Los datos de ejemplo y resultados no son recomendaciones de diseño y no deben utilizarse para fabricar, aprobar o declarar segura una suspensión real.**

