# Modelo de datos v0.3

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

Su schema permanece en `0.2.0`: v0.3 no cambia el solver ni la geometría persistida.

## CornerKinematicAnalysis

Struct escalar, sin estado oculto, derivado de un `KinematicResult`:

```matlab
analysis.schemaVersion                % "0.3.0"
analysis.kind                         % "CornerKinematicAnalysis"
analysis.cornerId
analysis.requestedWheelTravel_m
analysis.wheelTravel_m                % achieved; NaN si no convergió
analysis.camber_rad
analysis.toe_rad
analysis.caster_rad
analysis.kingpinInclination_rad
analysis.steeringAxis                 % LBJ -> UBJ, unitario
analysis.converged
analysis.status
analysis.failureReason
analysis.solverDiagnostics
```

Un estado no convergido conserva travel solicitado, status, causa y diagnósticos, pero publica travel logrado, ejes y métricas como `NaN`.

## BumpSweepAnalysis

Mantiene exactamente el orden y cardinalidad del `BumpSweepResult`:

```matlab
sweepAnalysis.requestedWheelTravel_m
sweepAnalysis.wheelTravel_m
sweepAnalysis.camber_rad
sweepAnalysis.staticToe_rad
sweepAnalysis.toe_rad
sweepAnalysis.bumpSteer_rad
sweepAnalysis.caster_rad
sweepAnalysis.kingpinInclination_rad
sweepAnalysis.steeringAxis            % N-by-3
sweepAnalysis.converged
sweepAnalysis.status
sweepAnalysis.failureReason
sweepAnalysis.solverElapsedTime_s
sweepAnalysis.analysisElapsedTime_s
sweepAnalysis.states                  % CornerKinematicAnalysis N-by-1
```

No interpola estados fallidos. Los vectores de métricas contienen `NaN` en la misma posición que el fallo del solver.

## API pública nueva

```matlab
result = fsd.kinematics.solveBump(geometry, wheelTravel, unit)
result = fsd.kinematics.solveBump(geometry, wheelTravel, unit, options)

sweep = fsd.kinematics.solveBumpSweep(geometry, travelVector, unit)
sweep = fsd.kinematics.solveBumpSweep(geometry, travelVector, unit, options)

camber_rad = fsd.kinematics.camberFromWheelAxis(wheelAxis, cornerId)
handles = fsd.kinematics.plotBumpResult(geometry, result, axesHandle)
settings = fsd.kinematics.solverSettings(overrides)

camber_rad = fsd.analysis.camberFromWheelAxis(wheelAxis, cornerId)
toe_rad = fsd.analysis.toeFromWheelAxis(wheelAxis, cornerId)
axis = fsd.analysis.steeringAxisFromPoints(lbj_m, ubj_m)
caster_rad = fsd.analysis.casterFromSteeringAxis(axis)
kpi_rad = fsd.analysis.kingpinInclination(axis, cornerId)
stateAnalysis = fsd.analysis.analyzeCornerState(geometry, result)
sweepAnalysis = fsd.analysis.analyzeBumpSweep(geometry, sweep)
handles = fsd.analysis.plotBumpSweepAnalysis(sweepAnalysis)

R = fsd.geometry.rotationVectorToMatrix(rotationVector_rad)
points = fsd.geometry.transformPointsRigid(points, reference, translation, R)
```

La API v0.1 de construcción, consulta, reflexión, métricas y MAT permanece con las mismas firmas. La API v0.2 también permanece; `fsd.kinematics.camberFromWheelAxis` es un wrapper compatible.

## Persistencia

MAT sigue siendo el formato canónico. Solo se persiste `DoubleWishboneGeometry`; estados, resultados y caches no se guardan automáticamente. La carga revalida schema e invariantes.

## Error IDs añadidos

- modelo: `CoincidentTieRod`, `CoincidentUprightPoints`, `DegenerateUpright`, `ZeroLengthUcaLink`, `ZeroLengthLcaLink`;
- geometría: `InvalidRotationVector`, `InvalidRotationMatrix`, `InvalidPoints`, `InvalidReferencePoint`, `InvalidTranslation`;
- cinemática: `InvalidWheelTravel`, `InvalidOptions`, `MissingOptimizationToolbox`, `InvalidWheelAxisOrientation`, `InvalidResult`.
- análisis: `InvalidGeometry`, `InvalidKinematicResult`, `InvalidBumpSweep`, `InvalidSweepAnalysis`, `InvalidWheelAxis`, `DegenerateWheelAxis`, `NonUnitWheelAxis`, `InvalidWheelAxisOrientation`, `DegenerateToeProjection`, `InvalidPoint`, `InvalidSteeringAxis`, `DegenerateSteeringAxis`, `NonUnitSteeringAxis`, `DegenerateCasterProjection`, `DegenerateKingpinProjection`, `InvalidCorner`, `InvalidFigure`.
