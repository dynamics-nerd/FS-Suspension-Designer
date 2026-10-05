# Modelo de datos v0.1

## Decisión

La geometría es un `struct` escalar. Los hardpoints se almacenan de forma columnar con matrices `double` y arrays `string`; no se crean clases, `SuspensionState` ni `KinematicResult`.

La representación favorece serialización MAT, validación explícita, acceso desde App Designer y una futura conversión a matrices densas para optimización.

## Estructura exacta de `DoubleWishboneGeometry`

```matlab
geometry.schemaVersion                 % "0.1.0"
geometry.kind                          % "DoubleWishboneGeometry"
geometry.cornerId                      % FL, FR, RL o RR

geometry.referenceFrame.id             % "VEHICLE_GLOBAL"
geometry.referenceFrame.originDescription
geometry.referenceFrame.axisConvention % "X_REAR_Y_RIGHT_Z_UP"

geometry.hardpoints.ids                % N-by-1 string, IDs completos
geometry.hardpoints.xyz_m              % N-by-3 double
geometry.hardpoints.sourceKind         % N-by-3 string
geometry.hardpoints.sourceNote         % N-by-3 string
geometry.hardpoints.displayName        % N-by-1 string

geometry.connectivity.memberIds        % 6-by-1 string
geometry.connectivity.pointIds         % 6-by-2 string

geometry.upright.pointIds              % UBJ, LBJ y WHEEL_CENTER

geometry.wheel.centerId
geometry.wheel.contactPatchId
geometry.wheel.wheelAxis               % 1-by-3 unit vector

geometry.metadata.lengthUnit           % "m"
geometry.metadata.coordinateSystem     % "X_REAR_Y_RIGHT_Z_UP"
```

La conectividad describe dos legs de UCA, dos de LCA, el segmento UBJ–LBJ y la referencia Wheel Center–Contact Patch. No impone restricciones de movimiento.

## API pública — DM-001 cerrada

### Modelo

```matlab
geometry = fsd.model.createDoubleWishboneGeometry( ...
    cornerId, ids, xyz, inputUnit, wheelAxis)

geometry = fsd.model.createDoubleWishboneGeometry( ...
    cornerId, ids, xyz, inputUnit, wheelAxis, provenance)

isValid = fsd.model.validateDoubleWishboneGeometry(geometry)
xyz_m = fsd.model.getPoint(geometry, pointId)
tolerances = fsd.model.numericTolerances()
roles = fsd.model.requiredHardpointRoles()
fsd.model.saveGeometryMat(filePath, geometry)
geometry = fsd.model.loadGeometryMat(filePath)
```

`provenance.sourceKind` y `provenance.sourceNote` pueden ser escalares, `N×1` o `N×3`; el constructor los expande a `N×3`. Los índices de fila no forman parte del API.

### Geometría estática

```matlab
vector_m = fsd.geometry.vectorBetweenPoints(geometry, fromId, toId)
distance_m = fsd.geometry.distanceBetweenPoints(geometry, idA, idB)
unitVector = fsd.geometry.unitVectorBetweenPoints(geometry, fromId, toId)
metrics = fsd.geometry.staticMetrics(geometry)
reflected = fsd.geometry.reflectDoubleWishboneGeometry(geometry)
handles = fsd.geometry.plotDoubleWishboneGeometry(geometry)
handles = fsd.geometry.plotDoubleWishboneGeometry(geometry, axesHandle)
```

Todas las funciones son puras salvo las fronteras explícitas de plot y persistencia.

## Error IDs públicos

Los callers pueden distinguir fallos mediante IDs estables. Los principales son:

- `fsd:model:InvalidCorner`, `InvalidIds`, `DuplicateId`, `UnknownId`, `MissingRequiredId` y `CornerPrefixMismatch`;
- `fsd:model:InvalidXyzType`, `InvalidXyzShape`, `NonFiniteCoordinate` e `InvalidInputUnit`;
- `fsd:model:InvalidProvenanceShape` e `InvalidProvenanceKind`;
- `fsd:model:CoincidentUBJLBJ`, `CoincidentUcaPivots`, `CoincidentLcaPivots` y `CoincidentWheelReferences`;
- `fsd:model:InvalidWheelAxis`, `ZeroWheelAxis`, `WheelAxisNotUnit` y `WheelAxisNotOutward`;
- `fsd:model:PointNotFound`, `InvalidMatPath` e `InvalidMatContents`;
- `fsd:geometry:CoincidentPoints` e `InvalidAxes`.

El texto del mensaje puede mejorar; el identificador es el contrato para tests y futuras interfaces.

## Wheel y upright

`upright` es conectividad mínima y no calcula pose. `wheel` referencia centro, contact patch y eje unitario. No se inventan radio, anchura ni un disco de rueda.

## Persistencia — DM-002 cerrada

MAT es el formato canónico de V1. `saveGeometryMat` guarda únicamente la variable `geometry`; `loadGeometryMat` exige esa variable y vuelve a validar el objeto. JSON queda reservado como posible intercambio futuro.

## Evolución

Todo cambio incompatible debe actualizar `schemaVersion` y aportar una migración explícita. No se serializan gráficos, resultados derivados ni caches.
