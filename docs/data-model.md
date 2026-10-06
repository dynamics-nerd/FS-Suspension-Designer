# Modelo de datos v0.2

## DoubleWishboneGeometry

Continúa siendo un struct escalar y serializable. Cambios respecto a v0.1:

- `schemaVersion = "0.2.0"`;
- diez hardpoints obligatorios;
- conectividad con miembro `TIE_ROD`;
- `upright.pointIds` contiene UBJ, LBJ, tie-rod-outboard, Wheel Center y Contact Patch.

```matlab
geometry.hardpoints.ids          % 10-by-1 string
geometry.hardpoints.xyz_m        % 10-by-3 double
geometry.hardpoints.sourceKind   % 10-by-3 string
geometry.hardpoints.sourceNote   % 10-by-3 string
geometry.hardpoints.displayName  % 10-by-1 string

geometry.upright.pointIds        % 5-by-1 string
geometry.wheel.centerId
geometry.wheel.contactPatchId
geometry.wheel.wheelAxis         % 1-by-3 unit vector
```

Las demás declaraciones de frame, metadata y procedencia se mantienen.

## SuspensionState

Solo aparece ahora que existe movimiento:

```matlab
state.schemaVersion       % "0.2.0"
state.kind                % "SuspensionState"
state.pointIds            % UBJ, LBJ, TIE_ROD_OUTBOARD, WC, CP
state.xyz_m               % 5-by-3 current positions
state.ubj_m
state.lbj_m
state.tieRodOutboard_m
state.wheelCenter_m
state.contactPatch_m
state.wheelAxis
state.wheelTravel_m
```

## KinematicResult

```matlab
result.schemaVersion
result.kind                       % "KinematicResult"
result.requestedWheelTravel_m
result.achievedWheelTravel_m
result.converged
result.status                     % CONVERGED / NO_CONVERGENCE / NOT_ATTEMPTED
result.failureReason
result.state                      % SuspensionState
result.uprightPose.referencePointStatic_m
result.uprightPose.translation_m
result.uprightPose.rotationVector_rad
result.uprightPose.rotationMatrix
result.wheelAxis
result.camber_rad
result.diagnostics
```

Diagnostics incluyen solver/toolbox, IDs de constraints, errores dimensionales, residuos escalados, exit flag, iteraciones, evaluaciones, pasos de continuación y mensaje.

Si no converge, `converged=false` y la pose, puntos, wheel axis y camber son `NaN`; no se publica una configuración falsa.

## BumpSweepResult

Contiene vectores de travel solicitado/logrado, camber, flags, tiempo total y cada `KinematicResult`. El orden de entrada se conserva y sirve como recorrido de continuation.

## API pública nueva

```matlab
result = fsd.kinematics.solveBump(geometry, wheelTravel, unit)
result = fsd.kinematics.solveBump(geometry, wheelTravel, unit, options)

sweep = fsd.kinematics.solveBumpSweep(geometry, travelVector, unit)
sweep = fsd.kinematics.solveBumpSweep(geometry, travelVector, unit, options)

camber_rad = fsd.kinematics.camberFromWheelAxis(wheelAxis, cornerId)
handles = fsd.kinematics.plotBumpResult(geometry, result, axesHandle)
settings = fsd.kinematics.solverSettings(overrides)

R = fsd.geometry.rotationVectorToMatrix(rotationVector_rad)
points = fsd.geometry.transformPointsRigid(points, reference, translation, R)
```

La API v0.1 de construcción, consulta, reflexión, métricas y MAT permanece con las mismas firmas. `requiredHardpointRoles` devuelve ahora los diez roles v0.2.

## Persistencia

MAT sigue siendo el formato canónico. Solo se persiste `DoubleWishboneGeometry`; estados, resultados y caches no se guardan automáticamente. La carga revalida schema e invariantes.

## Error IDs añadidos

- modelo: `CoincidentTieRod`, `CoincidentUprightPoints`, `DegenerateUpright`, `ZeroLengthUcaLink`, `ZeroLengthLcaLink`;
- geometría: `InvalidRotationVector`, `InvalidRotationMatrix`, `InvalidPoints`, `InvalidReferencePoint`, `InvalidTranslation`;
- cinemática: `InvalidWheelTravel`, `InvalidOptions`, `MissingOptimizationToolbox`, `InvalidWheelAxisOrientation`, `InvalidResult`.
