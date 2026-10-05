# Testing strategy

Flujo requerido:

> Engineering change → Unit test → Known case → Validation → Merge

Ejecute desde la raíz:

```matlab
results = runProjectTests;
```

`TestRepositoryFoundation` comprueba namespace y documentación. `TestStaticDoubleWishboneGeometry` cubre:

- construcción en m y mm y conversión explícita;
- normalización de wheel axis y procedencia por coordenada;
- matrices, IDs, corner, prefijos, NaN e Inf inválidos;
- hardpoints ausentes o duplicados;
- cuatro degeneraciones geométricas elementales;
- wheel axis nulo, inválido o orientado hacia dentro;
- consulta por ID y error para ID inexistente;
- distancia y vector unitario analíticos;
- métricas estáticas;
- reflexión FL→FR, wheel axis y doble reflexión;
- save/load MAT;
- handles y escala del plot 3D.

Los datos del fixture son ficticios. Las comprobaciones exactas de `0.280 m` y `[1,0,0]` se derivan directamente de sus coordenadas, no de la salida de la implementación.
