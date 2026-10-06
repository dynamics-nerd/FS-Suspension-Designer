# Modelo de datos v0.4

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

El contrato exige todos esos campos. `pointIds` sigue el orden canónico UBJ, LBJ, tie-rod-outboard, Wheel Center y Contact Patch. Cada campo conveniente debe coincidir con su fila en `xyz_m`; `state.wheelAxis` debe ser unitario y `state.wheelTravel_m` escalar.

El payload tiene dos modos válidos:

- `FINITE`: todos los datos móviles son finitos para un resultado convergido;
- `NAN`: todas las coordenadas, wheel axis y wheel travel son `NaN` para un resultado no convergido.

No se admiten estados parciales ni mezclas finite/NaN.

## KinematicResult

```matlab
result.schemaVersion               % "0.3.0"
result.kind                       % "KinematicResult"
result.geometryIdentity
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

Diagnostics incluyen solver/toolbox, `attempted`, IDs de constraints, errores dimensionales, residuos escalados, exit flag, iteraciones, evaluaciones, pasos de continuación y mensaje.

Invariantes:

- `converged=true` implica `status="CONVERGED"`, state/pose/wheel axis/camber finitos y `failureReason` vacío;
- `converged=false` implica `NO_CONVERGENCE` o `NOT_ATTEMPTED`, `failureReason` no vacío y payload móvil `NaN`;
- `state.wheelAxis == result.wheelAxis`;
- campos convenientes del state, pose, matriz/rotation vector, wheel travel y camber deben ser mutuamente coherentes;
- las cinco longitudes externas UCA FWD/AFT, LCA FWD/AFT y tie rod deben satisfacer la geometría de `geometryIdentity`;
- `geometryIdentity` debe ser válida.

Relación obligatoria con diagnostics:

```text
CONVERGED       <=> converged=true  y attempted=true
NO_CONVERGENCE  <=> converged=false y attempted=true
NOT_ATTEMPTED   <=> converged=false y attempted=false, sin actividad solver
```

## BumpSweepResult

Contiene schema `0.3.0`, `geometryIdentity`, vectores de travel solicitado/logrado, camber, flags, tiempo total y cada `KinematicResult`. El orden de entrada se conserva y sirve como recorrido de continuation.

Todos los resultados contenidos deben tener la misma identidad, cardinalidad y valores agregados que el sweep.

## DoubleWishboneGeometryIdentity

Representación canónica versionada generada por `fsd.model.geometryIdentity`:

```matlab
identity.schemaVersion            % "1.0.0"
identity.kind                     % "DoubleWishboneGeometryIdentity"
identity.geometrySchemaVersion    % "0.2.0"
identity.cornerId
identity.hardpointIds             % 10-by-1, orden canónico
identity.hardpointXyz_m           % 10-by-3, alineado con los IDs
identity.wheelAxis                % 1-by-3
```

Estos son exactamente los datos de geometría consumidos por el solver. Connectivity, nombres, metadata descriptiva y procedencia quedan fuera porque no alteran el cálculo. La comparación es exacta entre representaciones ya validadas y canónicas.

La identidad no es una prueba criptográfica de procedencia. `validateKinematicResult` demuestra en cambio que el payload satisface la pose rígida, el travel, el wheel axis y las cinco restricciones físicas de la geometría declarada.

## CornerKinematicAnalysis

Struct escalar, sin estado oculto, derivado de un `KinematicResult`:

```matlab
analysis.schemaVersion                % "0.3.0"
analysis.kind                         % "CornerKinematicAnalysis"
analysis.geometryIdentity
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
sweepAnalysis.geometryIdentity
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

identity = fsd.model.geometryIdentity(geometry)
fsd.model.validateGeometryIdentity(identity)
fsd.kinematics.validateSuspensionState(state, identity, payloadKind)
fsd.kinematics.validateKinematicResult(result)
fsd.kinematics.validateBumpSweepResult(sweep)

R = fsd.geometry.rotationVectorToMatrix(rotationVector_rad)
points = fsd.geometry.transformPointsRigid(points, reference, translation, R)
```

La API v0.1 de construcción, consulta, reflexión, métricas y MAT permanece con las mismas firmas. La API v0.2 también permanece; `fsd.kinematics.camberFromWheelAxis` es un wrapper compatible.

## AxleGeometry y AxleGeometryIdentity

`AxleGeometry` es un struct escalar; no duplica hardpoints:

```matlab
axle.schemaVersion       % "0.4.0"
axle.kind                % "AxleGeometry"
axle.axleId              % FRONT o REAR
axle.leftGeometry        % FL o RL
axle.rightGeometry       % FR o RR
```

`AxleGeometryIdentity` incluye schema, axle ID y las dos
`DoubleWishboneGeometryIdentity` completas. No contiene una referencia X: el
análisis frontal se deriva por esquina de la cinemática 3D. Permite geometría
asimétrica y wheel stagger.

## AxleKinematicResult y AxleHeaveSweepResult

`AxleKinematicResult` compone, sin copiar sus estados internos, un
`KinematicResult` izquierdo y otro derecho:

```matlab
result.axleIdentity
result.requestedWheelTravel_m
result.leftResult
result.rightResult
result.leftConverged
result.rightConverged
result.converged          % true solo si ambos convergen
result.status
result.failureReason
```

El status agregado es `CONVERGED` si ambos convergen, `NOT_ATTEMPTED` si
ninguno fue intentado y `NO_CONVERGENCE` en los demás casos, incluida
convergencia unilateral. El sweep conserva ambos `BumpSweepResult`, sus flags
por lado y los resultados compuestos por target.

## FrontViewInstantCenter y AxleRollCenterAnalysis

Cada FVIC conserva las restricciones cinemáticas UCA/LCA, sus líneas YZ
homogéneas, status, diagnóstico, conditioning y coordenadas solo cuando son
finitas. Un IC `INFINITE` conserva `homogeneousPoint=[dy,dz,0]` y
`direction_yz`, mientras sus coordenadas euclídeas son `NaN`.

`AxleRollCenterAnalysis` conserva:

```matlab
analysis.axleIdentity
analysis.status
analysis.rollCenterY_m
analysis.rollCenterZ_m
analysis.rollCenterHeight_m
analysis.rollCenterHeightStatus
analysis.roadReferenceZ_m
analysis.rollCenterHomogeneousPoint
analysis.rollCenterDirection_yz
analysis.rollCenterConditioning
analysis.rollCenterIllConditioned
analysis.left.instantCenter
analysis.left.geometricContact
analysis.left.rollCenterConstructionLine
analysis.right              % contrato equivalente
```

`AxleHeaveRollCenterAnalysis` añade vectores ordenados de Y, Z y altura,
tiempos separados y el análisis por target. Un punto sin convergencia bilateral
no publica roll center y recibe un payload inválido nuevo: no clona Wheel
Center, wheel axis, contacto, ejes de pivotes ni líneas del estado estático.

## API pública v0.4

```matlab
axle = fsd.model.createAxleGeometry(leftGeometry, rightGeometry)
fsd.model.validateAxleGeometry(axle)
identity = fsd.model.axleIdentity(axle)
fsd.model.validateAxleIdentity(identity)

result = fsd.kinematics.solveAxleHeave(axle, travel, unit)
sweep = fsd.kinematics.solveAxleHeaveSweep(axle, travelVector, unit)
fsd.kinematics.validateAxleKinematicResult(result)
fsd.kinematics.validateAxleHeaveSweepResult(sweep)

ic = fsd.analysis.frontViewInstantCenter(geometry)
ic = fsd.analysis.frontViewInstantCenter(geometry, kinematicResult)
contact = fsd.analysis.geometricWheelContact(geometry)
analysis = fsd.analysis.analyzeAxleState(axle)
analysis = fsd.analysis.analyzeAxleState(axle, result)
migration = fsd.analysis.analyzeAxleHeaveSweep(axle, sweep)
handles = fsd.analysis.plotAxleFrontView(analysis)
handles = fsd.analysis.plotRollCenterMigration(migration)
```

## Persistencia

MAT sigue siendo el formato canónico. La persistencia automática continúa
limitada a `DoubleWishboneGeometry`; axle, estados, resultados y caches no se
guardan automáticamente en v0.4.

## Error IDs añadidos

- modelo: `CoincidentTieRod`, `CoincidentUprightPoints`, `DegenerateUpright`, `ZeroLengthUcaLink`, `ZeroLengthLcaLink`;
- geometría: `InvalidRotationVector`, `InvalidRotationMatrix`, `InvalidPoints`, `InvalidReferencePoint`, `InvalidTranslation`;
- cinemática: `InvalidWheelTravel`, `InvalidOptions`, `MissingOptimizationToolbox`, `InvalidWheelAxisOrientation`, `InvalidResult`.
- identidad/modelo: `InvalidGeometryIdentity`;
- contratos cinemáticos: `InvalidSuspensionState`, `InvalidKinematicResult`, `InvalidBumpSweepResult`;
- análisis: `InvalidGeometry`, `GeometryMismatch`, `InvalidKinematicResult`, `InvalidBumpSweep`, `InvalidSweepAnalysis`, `InvalidWheelAxis`, `DegenerateWheelAxis`, `NonUnitWheelAxis`, `InvalidWheelAxisOrientation`, `DegenerateToeProjection`, `InvalidPoint`, `InvalidSteeringAxis`, `DegenerateSteeringAxis`, `NonUnitSteeringAxis`, `DegenerateCasterProjection`, `DegenerateKingpinProjection`, `InvalidCorner`, `InvalidFigure`.
