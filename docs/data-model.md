# Modelo de datos

## Aclaración de edición ARB — V23-F-02

El plan declarado del escenario conserva los tipos, formas y campos opcionales
almacenados; no se confunde con el plan preparado en double por el evaluador.
ArbView conserva la definición cargada y convierte únicamente las entradas
editadas. Su snapshot de definición/controles es memoria transitoria de la vista,
sin nuevos campos persistentes o identidades. MAT y el historial mantienen sus
contratos actuales. [Detalle de preservación](v0.23-f02-validation.md).

## Extensión v0.23

`AntiRollBar0.23` es un valor plano SI con `definition` e `identity`, revisión,
eje, representación, puertos, ajuste, referencia, ley, parámetros/procedencia y
frame completo. No hay objetos proveedor, handles ni caché persistente. Parámetro
desconocido `[]`; los números disponibles son double canónico. Identidad excluye
sólo nombre/nota descriptivos, conserva revisión e hipótesis físicas.

`resources.antiRollBars` es una biblioteca opcional de revisiones inmutables;
`arbAssignments` enlaza eje/ID/revisión exactos. Un registro puede estar incompleto;
readiness es por operación. ARB_KINEMATICS/ARB_MECHANICAL consumen una revisión y
un plan explícito, con padres nativos sólo para la geometría/ROLL que los necesita.
ARB_SIZING consume G, longitud, sección/diámetro interior y target con procedencia;
no necesita un mecanismo completo. El resultado conserva fuentes, movimiento,
estudio, diagnósticos y packaging solicitado. No se insertan curvas en el recurso.

GLOBAL_STATIC añade opcionalmente `inputs.arbAxles` y consume las asignaciones
vigentes. Sistema/preparación/estado/resultado físicos son0.23 sólo con ARB activa;
sin ella conservan0.10. Los envelopes de proyecto/escenario/resultado/MAT
históricos continúan, con whitelist consumidora0.23 ampliada. Cargar MAT antiguo
no añade recursos ARB ni reetiqueta resultados. [Esquemas y APIs](anti-roll-bar.md).

## Extensión v0.22

TireDefinition0.22 conserva definición SI, identidad y verticalIdentity. Geometría,
vertical, familia/parámetros, leyes, dominios y procedencia se mantienen separados;
[] significa desconocido. resources.tires y tireAssignments son opcionales y no
se añaden a proyectos antiguos al leerlos. Revisiones registradas son inmutables;
asignaciones cornerId/tireId/tireRevision pueden compartir el mismo recurso.
Curvas viven en EngineeringResult, no en cada revisión.

TIRE_CHARACTERIZATION conserva referencia exacta, estados/orden/request y
TireResponse0.22. Proyecto/escenario/resultado lógicos0.16 y envelope MAT existente
continúan; se amplían versiones consumidoras sin reescribir snapshots históricos.
GLOBAL_STATIC tiene inputs.tires histórico o tireSource=LIBRARY_ASSIGNMENTS,
exclusivos. El contexto nuevo incluye sólo ID y proyección vertical consumida.
No handles, objetos proveedor ni radio efectivo inferido. [Contrato](tire-models-foundation.md).

Correcciones V22-F-01/02/03: request vacío conserva su declaración persistida,
con defaults sólo en evaluación/presentación; se mantiene el orden de canales.
Un plan vacío sigue siendo declaración pendiente editable. La proyección de
dependencias de caracterización es efímera: no sustituye prepared.context ni
identidades históricas, y no cambia el esquema MAT. La fábrica convierte valores
enteros seguros y single a double antes de construir identidades; validate exige
esta representación canónica. Ningún valor físico desconocido se completa.

## Extensión v0.21

EngineeringScenario existente admite engine GLOBAL_STATIC y scope VEHICLE. No se
amplía el registry con modelos duplicados: geometrías/actuaciones/coilovers son
recursos existentes; `inputs.tires` contiene cuatro VerticalTireModel nativos
ordenados FL/FR/RL/RR. El concepto existente aporta masa operativa, convención de
inclusión del piloto, dimensiones, CG XYZ y masas no suspendidas. Plan explícito:
vehicleOptions, systemOptions, cornerPlans y initialGuesses; options usa el
contrato numérico0.10. La aproximación de masa cero debe seleccionarse expresamente.

PreparedEngineeringScenario global añade cuatro preparaciones MECHANICAL, los
tires y vehículo/loadCase; su context registra todas las dependencias consumidas.
Payload global cerrado: system y equilibrium. Cada source de system conserva el
BumpSweep original adicional a los snapshots ActuationSweep/Mechanical para
vincular la evidencia a su plan. No se embeben EngineeringResults padres ni ledger.
El validator comprueba por esquina los recursos/paths y reconstruye el aggregate
nativo; valida ecuaciones/selección sin generar forwards. Los tiempos no autentican
la historia de ejecución. Resultado lógico0.16, modelos0.7/0.8/0.9/0.10 y MAT0.19
conservados. Software consumidor0.21; no migración implícita al abrir anteriores.
Historial inmutable y clasificación selectiva por context, no sólo por IDs.
[Campos, contratos y límites](guided-global-static.md).

## Integración v0.20

No nuevos esquemas físicos: se reutilizan ActuationGeometry0.7, SpringDamperModel0.8,
síntesis0.15 y proyecto/escenario/resultado0.16. Software0.20.0 admitido junto a las
versiones previas en resultados y PackagingSourceReference; storage0.19 intacto.
Los recursos del corner se registran/adoptan como par coherente. Metadata conserva
`parameterProvenance.<ID>.sourceKind/sourceNote`; otras claves existentes se preservan.
No se convierten fuentes/labels en identidad física ni se borra el ledger al revisar.

Escenarios UI_ACTUATION/MECHANICAL/ACT_SEARCH por corner guardan plan SI completo,
specification/targetOrigins y opciones nativas. Una fila sin editar conserva el
objeto exacto; anotar un target no pierde incertidumbres/tolerancia numérica ocultas.
Resultados originales y candidatos mantienen sus propios snapshots; la adopción
copia los recursos exactos y cambia sólo la configuración actual. MAT recupera todo
el proyecto lógico. Drafts/cámara/selección de la vista son estado temporal, no un
segundo modelo persistido. [Campos, firmas y fronteras](guided-actuation-mechanics.md).

## Packaging v0.19

Structs canónicos de valores (schema0.19), sin handles en el núcleo:
PackagingVolume conserva definición SI e identity, bindings FIXED/UPRIGHT/
SEGMENT, frame y procedencia; PackagingDefinition agrupa celdas de volúmenes,
pares y regiones; PackagingResult conserva definición, geometría, plan, fuente,
estados resueltos, checks, cobertura y limitaciones. Los validadores reconstruyen
el resultado sin solves físicos. Las dimensiones vacías significan desconocidas.
`resources.packaging` es opcional: no se añade a proyectos anteriores al leerlos.
PACKAGING usa EngineeringScenario/EngineeringResult históricos; sus valores
lógicos conservan schema0.16 y el software nuevo es0.19.0. Las dependencias consumidas se incluyen
en el contexto canónico de compatibilidad, no en un sistema paralelo de staleness.
PackagingSourceReference conserva sourceIdentity, revisión/ID/software de origen,
payload/assessment nativos y un dependencySnapshot sin ledger, escenarios ni
recursos Packaging. Su preparación debe ser exactamente igual a la del resultado
original; no se etiqueta como su configuración original completa ni como ejecución.
El ledger conserva el EngineeringResult íntegro. La compatibilidad de la referencia
usa resultCompatibility; nunca se clasifica como CURRENT_EXECUTION por una proyección.
Ver [campos y APIs](packaging-physical-feasibility.md).

Persistencia de proyectos con Packaging o con historial de resultados: un único MAT nativo, cabecera física
`FsdEngineeringProjectStorage`0.19 / `FSD_VALUE_GRAPH_V1`, configuración y una variable
`FSD_RESULT_000001` por registro. Se reconstruye exactamente el proyecto original;
no se eliminan históricos ni se modifican tipos/valores numéricos. Un DAG local
con referencias hacia nodos anteriores conserva shapes, clases y bits numéricos;
un diccionario char distingue missing de texto literal. Los structs del usuario
no se reinterpretan como marcadores. La igualdad de contenedores se demuestra
por shape, campos ordenados y referencias exactas a hijos ya codificados;
las primitivas densas de hasta128 elementos usan claves con sus bits íntegros.
Arrays mayores y sparse se conservan sin interning; no se limita su capacidad.
No se comparan ni retienen árboles originales completos, ni se usa un hash.
Un diccionario local reutiliza listas exactas de nombres de campos ordenados e
IDs de texto; su clave contiene cantidad, longitudes y UTF-16 completo. No omite
visitar valores ni cambia el orden de nodos/textos. Se descarta con el codec.
El lector sigue
admitiendo el anterior `FSD_TEXT_V1` de desarrollo, además de
`FsdEngineeringProjectFile`0.16. Los proyectos clásicos sin Packaging y SIN
resultados siguen escribiendo ese formato anterior. Cualquier historial nuevo
usa la escritura acotada0.19, incluso sin Packaging: el serializador antiguo
también generaba picos de memoria con snapshots de síntesis. Los ficheros nuevos
de historial requieren el lector0.19; la lectura de MAT0.18 anteriores se mantiene.
Usar las APIs canónicas de carga, no
suponer que todos los MAT nuevos exponen `envelope.project` directamente.
El cambio responde a presión de memoria observada, no a una nueva física o DB.

No se guarda ningún contexto de validación, callback, Map ni pool dentro de un
proyecto. Los contextos privados de una operación se descartan al retornar.
Cada resultado conserva su configuración ORIGINAL completa; reducir el request
del worker no reduce ese snapshot, porque el ledger ya estaba excluido de él.

## Sesión UI v0.18

No nuevo formato físico ni persistencia paralela. El Controller handle vive sólo
en memoria; contiene EngineeringProject nativo, epoch, operationId, Future y
ownership del pool. Los requests/responses entre procesos son structs/celdas
de valores y no contienen handles gráficos. Las tablas son borradores de
presentación; Apply usa las fábricas originales. MAT conserva envelope0.16 y
ledger original; fsdVersion0.18 se admite como consumidor compatible junto a0.16/0.17.
Las decisiones construidas mantienen schema0.17. Cambios invalidan respuestas
por epoch y resultados dependientes mediante resultCompatibility nativo.
[Datos UI y persistencia](guided-design-interface.md).

## Contratos v0.17

ParametricSeedDefinition/Result0.17.0 son structs con decisiones DesignParameter
nativas, referencias físicas conceptuales, corner/symmetry, constraints,
readiness, nominalStatus, sampledStatus, geometries/axle/frames/derivations,
consistency, assessment e identity. Derivaciones conservan IDs por punto e inputs.
ParametricSeedBumpCheck0.17.0 retiene plan, fuentes nativas, análisis, quality y
snapshots. EngineeringScenario/Project/Result y envelope MAT0.16 permanecen
aditivos; software0.16/0.17 se admite explícitamente, construcción sólo0.17.
resources.seedBindings opcional liga escenario/proyecto/revisión y construcción
a geometrías registradas. Ausente conserva la forma anterior. Sin migración ni
clases nuevas. [Campos y estados](concept-to-seed.md).

## Contratos v0.16

Structs funcionales consumidores, schema 0.16.0: ConceptParameter (parámetro
v0.11+estado/confirmación/origen), VehicleConcept (cantidades progresivas),
ConceptDerivation (inputs+modelo+outputs condicionados), EngineeringScenario
(intent/scope/spec/planes/opciones), EngineeringProject (configuración/revisión,
recursos/escenarios opcionales y ledger), EngineeringResult (snapshot ORIGINAL,
contexto preparado, payload nativo y assessment). Sin clases, handles o servicios.
`[]` significa valor ausente acompañado de estado; NaN sólo donde el contrato
físico histórico lo requiere. Identidades completas sin hash. El ledger no
cambia la identidad de configuración. La compatibilidad se calcula, no se
confía en un flag almacenado. MAT envelope FsdEngineeringProjectFile0.16.0;
los MAT anteriores siguen con sus APIs, sin migración de metadata inventada.
[Campos/APIs y estados](vehicle-concept-project-workflow.md).

## Contratos v0.15

ActuationSynthesisDesignSpace/Evaluation/Result son structs schema0.15.0/MAT;
no clases/handles persistentes. Space conserva seeds físicos nativos inmutables,
spec completa, plan canónico, aliases, cinco puntos nominales, variables/bounds
y componente dependiente del eje. Evaluation guarda modelos reconstruidos,
changes solicitados/logrados, identidades, snapshot, preflight y assessment,
wrappers BUMP/ACTUATION/MECHANICAL, fallos, calidad, score y tiempos.
Result conserva search v0.12 íntegro, selección, contadores y diagnósticos.
Las matrices de puntos son 5×3; el quinto representa una línea, no un bearing.
`DesignCandidate.definitionSI.actuations` sólo existe cuando se registran modelos
nominales. Omitido/vacío deja definición/identidad anteriores exactamente iguales.
Snapshot incluye parámetros mecánicos y contexto numérico, separados de
identidades físicas. Cada fuente se asocia al mismo mecanismo y BUMP.
[Campos/APIs/replay](actuation-geometry-synthesis.md).

## Contratos v0.14

SteeringSynthesisDesignSpace/Evaluation/Result y snapshot: structs0.14.0/MAT.
Reutilizan campos del eje: seedAxle/cornerSpaces/physicalVariables/variables,
independentIndex/multiplier/symmetryLinks/specification/sourceIds. Añaden
seedSteering nativo; plan.rack y referenceRackTravel_m=0. Evaluation añade
steering/steeringIdentity/mechanismDiagnostics y cuarto wrapper físico RACK,
después de BUMP L/R y ROLL opcional. Diagnósticos contienen longitudes tie rod
y rack seed/candidato, sin inputs de length redundantes. Snapshot separa seed
physical identity y contexto entero de planes/options/spec/links. Result retiene
search original; statistics.rackSweeps separa RACK de BUMP/ROLL/candidatos.
Un fallo atómico no publica modelo/identity parcial. MAT se revalida sin solves.
No clases/handles persistentes ni schemas físicos nuevos. [Contrato](steering-geometry-synthesis.md).

## Contratos v0.13

AxleSynthesisDesignSpace, AxleSynthesisEvaluation, AxleSynthesisResult y snapshot
son structs schema0.13.0. SeedAxle/AxleGeometry y sus dos identidades mantienen
schemas históricos. Space conserva spec/planes canónicos/cornerSpaces v0.12,
physicalVariables con ambas declaraciones, variables independientes,
independentIndex/multiplier y symmetryLinks. No clases/DB/handles persistidos.
Evaluation conserva axle/identity/changes, tres wrappers físicos independientes,
candidate/assessment conjuntos, disponibilidad/calidad/HARD/SOFT/score/tiempos.
Fallos de builder no publican eje ficticio; fallos de análisis conservan el sweep.
Result reutiliza search v0.12 íntegro y agrega snapshots/statistics/diagnostics.
MAT completo se valida tras load sin solves. [Campos y APIs](axle-level-synthesis.md).

## Contratos v0.12

SynthesisDesignSpace, SynthesisEvaluation y SynthesisResult son structs
schema0.12.0. No nuevas clases/enums/DB. Space conserva seed/spec/plan y
bindings v0.11 canónicos, initial/bounds/active. Evaluation conserva geometría,
identity, fuentes BUMP completas, assessment v0.11, cambios/provenance,
guard de conditioning/orientación, clasificación, score disponible y tiempos.
Result conserva problem, records únicos, keys, history por referencia de ID,
opciones/stop/selección/estadísticas/diagnósticos. Caché exacta local al espacio;
no estado persistente. Cada intento puede reconstruirse sin perder fallos.
Validadores reconstruyen geometría/evidencia y replay del controlador sin solves;
MAT round-trip validado. Schemas históricos intactos.
Correcciones V12-F-01/F-02: result/evaluation.execution captura inputs canónicos
del plan; evaluation.bumpEvidence liga snapshot/ID/geometría/sweep al solve.
failureStage y evidenceStatus distinguen rechazo del builder, excepción BUMP
sin sweep y fallo de análisis con sweep válido. Candidate/assessment vacíos y
score NaN son explícitos; no se generan fuentes incompletas para satisfacer
campos. Validación de fallos reconstruible sin solves. MAT pre-auditoría sin
estos campos debe regenerarse, no migrar provenance inventada.
[Campos, APIs y límites](inverse-suspension-synthesis.md).

## Contratos v0.11

Structs schema0.11.0 con kind/definitionSI/identity/metadata: DesignParameter,
DesignTarget, SuspensionDesignTargets, DesignConstraint, DesignSpecification y
DesignCandidate. Specification no exige geometrías: parámetros/targets/limits
pueden registrarse antes. Tipos/provenance compatibles con vocabulario v0.9.
Candidate agrega fuentes nativas tipadas y sus modelos; su identidad reemplaza
payloads pesados por IDs y controles. DesignAssessment contiene comparación y
readiness ligada a ambas identidades, nunca resultados inventados ni nuevos
solves. DesignComparison conserva evaluaciones bajo una única especificación.
Validadores reconstruyen registros y evaluación desde fuentes originales;
MAT round-trip probado. Sin jerarquía OO ni DB. Contrato, campos, catálogo,
scopes, unidades, bindings y APIs en
[design-requirements-target-evaluation.md](design-requirements-target-evaluation.md).

Tras auditoría F-01, la validación estructural de `model`/fábrica no equivale
a validez física conjunta. `analysis` reconstruye todas las fuentes y une sus
identidades físicas en un mapa privado por dominio/corner; registros nominales
siguen opcionales. Un candidato permite un vehículo/load case/configuración,
sin escenarios múltiples implícitos. Referencias y fuentes participan en la
misma invariante. Un assessment previo incoherente falla al validarse otra vez.
No se añaden campos públicos ni nuevos schemas: diagnósticos F-03 reutilizan
`reasons`, con prioridad explícita; fuentes nativas retienen causas secundarias.
Plot F-02 lee nudos originales de la especificación sin modificar assessments.

## Contratos v0.10

Structs serializables schema0.10.0: VerticalTireModel, GlobalStaticSystem,
PreparedGlobalStaticSystem, GlobalStaticState, GlobalStaticEquilibriumResult.
System compone vehículo/case y cuatro cells de fuentes/tire FL/FR/RL/RR;
geometry/actuation/springDamper/mechanical permanecen contratos originales.
Identity1.0.0 sin hash incluye parámetros físicos/paths/calidad/road/hipótesis;
metadata/display names excluidos. Prepared contiene pp, derivatives, segmentos,
nominal WC y sprung CG derivado; no es un cache confiado sin validación.
State conserva evaluación prescrita, U/gradient/H candidato/quality, corner
outputs, contactos, CG móvil, CW, balances world, alturas y referencia v0.9.
Result separa attempts de alternativas válidas y selectedIndex (NaN sin selección).
Campos numéricos indisponibles NaN; no se inventan roots o alturas nominales.
Validadores reconstruyen física/aceptación/estabilidad/selección, no sólo IDs.
[Campos y APIs](global-static-equilibrium.md). Se conservan schemas anteriores.

## Contratos v0.9

VehicleParameters y VehicleLoadCase son structs 0.9.0, independientes de las
cuatro geometrías. definitionSI preserva inputs, modo/inventarios/provenance;
modelo deriva M/CG coordenada a coordenada, sprungMass sólo con desglose completo.
Identities 1.0.0 incluyen inputs físicos/configuración/supuestos; metadata de
presentación queda fuera. No hashes, clases nuevas ni persistencia ajena a MAT.
StaticVehicleLoads conserva identidad, case, matriz y familia/bounds del
nullspace, closure explícito, medidas originales, residual, soporte y statuses.
CornerStaticEquilibrium preserva modelo/actuation/path completos, demanda,
opciones, todos los brackets/roots/flats, selección y reporting de precisión.
Validador reconstruye el payload, no sólo identities/flags. Sin root seleccionada
los campos numéricos del resumen son NaN; roots alternativas permanecen visibles.
Los contratos históricos no cambian. [Campos y APIs v0.9](vehicle-static-equilibrium.md).

Auditoría v0.9 (schema/versión siguen 0.9.0): family añade rawLambdaInterval_N,
lambdaBoundaryBudget_N, loadRoundoff_N, nullDirectionRoundoff, endpointLoads_N,
intervalClassification y admissibleDimension. Un punto numérico no modifica
degreeOfFreedom algebraico ni suministra cierre implícito. Resultado de cargas
añade normalRoundoffBudget_N, numericalClassification y supportRoundoffBudget_N.
Mediciones canónicas y candidatos se conservan; soporte negativo/irresoluble no
se publica como demanda aceptada. CornerStaticEquilibrium añade
flatIntervalFilterDiagnostics (algoritmo y contadores deterministas, no tiempos).
Los validadores reconstruyen también estos campos; payloads anteriores a esta
corrección deben regenerarse desde fuentes, no recibir flags inventados.

## Contratos mecánicos opcionales v0.8

`SpringDamperModel` es un struct, no una nueva jerarquía de clases. Contiene
`cornerId`, la `actuationIdentity` existente, `configuration="COILOVER"`,
`spring`, `damper`, `derivedStaticGeometry`, metadata e identity. No duplica
la geometría completa de actuación. Parámetros se almacenan en SI con
sufijos de unidad; límites opcionales ausentes se normalizan a `[]`.
La identity canónica 1.0.0 incluye todos los parámetros físicos, tablas,
límites y asociación; excluye metadata. Cambios de rate, preload o damping
cambian identity. Los contratos antiguos no cambian de schema.

`SpringDamperStateAnalysis` conserva source íntegro, modelIdentity y velocidad
axial prescrita, más `state` axial-only. Las métricas en rueda son NaN.
`SpringDamperSweepAnalysis` conserva source (sweep y análisis de actuación
íntegros, o camino prescrito explícito), path, velocidad en rueda N×1,
states N×1, curvas redundantes N×1, referencia nominal, métricas y timing.
No mezcla fuentes por dimensiones: compara identidad y payload upstream.
Los validadores reconstruyen leyes, geometría de asientos, statuses y
agregados. NaN significa no disponible; no se sustituye por cero.

F-01 mantiene schema/version 0.8.0 y SpringDamperModel sin cambios. Añade a
los sweeps `derivativeDiagnostics` (política F01-1, muestras, stencil/pesos,
candidatos, estimaciones/límites y flags), `motionRatioStatus` por estado/curva,
`validWheelRateSampleCount` y `wheelRateCoverageComplete`. Curvatura y MR
tienen disponibilidad independiente; los candidatos diagnósticos no sustituyen
curvas publicadas. El single-state axial-only no necesita estos diagnostics.
La reconstrucción completa verifica los campos nuevos. Un análisis mecánico
MAT previo a F-01 debe recalcularse desde source; no se añade migrador ni se
acepta un payload antiguo como si hubiera superado el nuevo criterio.

Persistencia: `save/load` MAT de structs, conservando identity/model/source
juntos; validar tras load. No se redefine el loader histórico de geometría
como un loader genérico ni se introduce otro formato. La metadata puede
registrar KNOWN/ASSUMED/sourceNote por parámetro; si falta, su procedencia no
se presume conocida. Véase [campos y APIs](spring-damper-wheel-rate.md).

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
limitada a `DoubleWishboneGeometry`; axle, steering, estados, resultados y
caches no se guardan automáticamente en v0.5.

## SteeringSystemGeometry

Es un struct escalar serializable, no una clase. Compone el eje delantero sin
duplicar sus hardpoints:

```matlab
steering.schemaVersion                 % "0.5.0"
steering.kind                          % "SteeringSystemGeometry"
steering.frontAxleGeometry             % AxleGeometry FRONT
steering.rackGeometry.leftInnerStatic_m
steering.rackGeometry.rightInnerStatic_m
steering.rackGeometry.axisDirection    % unitario, FL -> FR
steering.rackGeometry.jointSeparation_m
steering.rearAxleX_m                   % referencia mínima Ackermann
steering.identity                      % SteeringSystemGeometryIdentity
```

La identity contiene la identity completa del eje delantero, los extremos y
eje canónico del rack y `rearAxleX_m`. Cambiar una esquina, intercambiar
FL/FR o cambiar la referencia trasera produce otra identity.

## SteeringCornerResult y SteeringAxleResult

Cada esquina conserva state, pose, wheel axis, camber y diagnostics del
solver, y añade rack solicitado/logrado, inboard estático/actual, contacto
geométrico y un `rackZeroKinematicResult` a igual wheel travel. Esta referencia
permite separar steering de rack y bump steer sin repetir el solve en analysis.
Cada `SteeringCornerResult` conserva además `steeringSystemIdentity`; por ello
puede validarse de forma autónoma, incluida la traslación dirigida del rack,
sin reconstruir ni reejecutar el solver.

`SteeringAxleResult` compone FL/FR, la identity del sistema, targets de rack y
wheel travel, flags/status por lado, diagnostics agregados y tiempo. Solo es
`CONVERGED` si ambas esquinas convergen. Un corner fallido usa `NaN` en su
payload móvil y el análisis bilateral queda inválido.

## RackSweepResult y análisis

`RackSweepResult` conserva el orden exacto de rack travel, wheel travel FL/FR,
un `SteeringAxleResult` por target, convergencia/status y tiempo del solver.
La continuation se realiza sobre el recorrido ordenado, no mediante solves
independientes.

`SteeringAxleAnalysis` contiene por lado heading, ángulo absoluto, deflexión
desde estático, steering inducido por rack, toe, bump steer, eje de dirección,
contacto, intersección con el plano de contacto, scrub y mechanical trail. Su
bloque Ackermann contiene ICR FL/FR, dirección, inner/outer, mismatch, ángulos
actuales/ideal, error angular, status y conditioning.

`RackSweepAnalysis` agrega esas magnitudes en vectores sin aplanar ni perder
los states completos. No interpola fallos.

La validez de esas métricas es bilateral. Si solo converge una esquina, los
dos bloques laterales tienen status `KINEMATICS_NOT_CONVERGED` y magnitudes,
contacto e intersección derivados en `NaN`. Cada bloque conserva
`kinematicConverged`, `kinematicStatus`, `kinematicFailureReason` y
`solverDiagnostics`, por lo que invalidar el análisis no elimina el diagnóstico
individual.

## API pública v0.5

```matlab
steering = fsd.model.createSteeringSystem(frontAxle, rearAxleX, unit)
fsd.model.validateSteeringSystemGeometry(steering)
identity = fsd.model.steeringSystemIdentity(steering)

result = fsd.kinematics.solveSteering( ...
    steering, rackTravel, wheelTravel, unit)
sweep = fsd.kinematics.solveRackSweep( ...
    steering, rackTravelVector, wheelTravel, unit)

analysis = fsd.analysis.analyzeSteering(steering, result)
sweepAnalysis = fsd.analysis.analyzeRackSweep(steering, sweep)
handles = fsd.analysis.plotSteeringSystem(steering, result, analysis)
handles = fsd.analysis.plotSteeringSweep(sweepAnalysis)
```

`wheelTravel` puede ser escalar o `[left,right]`. Longitudes públicas aceptan
`"m"` o `"mm"`; el modelo y todos los resultados almacenan metros/radianes.

## Error IDs añadidos

- modelo: `CoincidentTieRod`, `CoincidentUprightPoints`, `DegenerateUpright`, `ZeroLengthUcaLink`, `ZeroLengthLcaLink`;
- geometría: `InvalidRotationVector`, `InvalidRotationMatrix`, `InvalidPoints`, `InvalidReferencePoint`, `InvalidTranslation`;
- cinemática: `InvalidWheelTravel`, `InvalidOptions`, `MissingOptimizationToolbox`, `InvalidWheelAxisOrientation`, `InvalidResult`.
- identidad/modelo: `InvalidGeometryIdentity`;
- contratos cinemáticos: `InvalidSuspensionState`, `InvalidKinematicResult`, `InvalidBumpSweepResult`;
- análisis: `InvalidGeometry`, `GeometryMismatch`, `InvalidKinematicResult`, `InvalidBumpSweep`, `InvalidSweepAnalysis`, `InvalidWheelAxis`, `DegenerateWheelAxis`, `NonUnitWheelAxis`, `InvalidWheelAxisOrientation`, `DegenerateToeProjection`, `InvalidPoint`, `InvalidSteeringAxis`, `DegenerateSteeringAxis`, `NonUnitSteeringAxis`, `DegenerateCasterProjection`, `DegenerateKingpinProjection`, `InvalidCorner`, `InvalidFigure`.
# Contratos v0.6

Los nuevos contratos siguen siendo structs funcionales y serializables; no se
añaden clases por estado ni una jerarquía full-vehicle.

- `AxleTravelResult` (`0.6.0`): identity de eje, target `[zLeft,zRight]`, dos
  `KinematicResult`, convergencia bilateral y diagnósticos.
- `AxleTravelSweepResult` (`0.6.0`): matriz target `N x 2`, sweeps de esquina
  con continuation y resultados bilaterales ordenados.
- `AxleRollResult` (`0.6.0`): `(phi,h)`, `[zLeft,zRight]`, resultado de recorrido,
  contactos, target/solved road lines, residual, error angular y diagnóstico
  del root solve.
- `AxleRollSweepResult` (`0.6.0`): vector de ángulos en el orden solicitado,
  heave escalar constante y estados de roll.
- `AxleRollAnalysis` (`0.6.0`): camber chassis/road, toe, FVIC/RC heredados,
  altura histórica y road-relative diferenciadas, tracks y referencia estática.
- `AxleRollSweepAnalysis` (`0.6.0`): arrays numéricos `N x 1` o `N x 2` y
  estados completos para trazabilidad.

En un sweep de análisis se separan dos conceptos:

- `kinematicStatus`: status exacto del `AxleRollResult`, incluido el motivo
  específico del fallo;
- `analysisStatus`: `CONVERGED` o `KINEMATICS_NOT_CONVERGED`, indicando si
  existen métricas interpretables.

Los arrays agregados usan `NaN` para targets fallidos o `NOT_ATTEMPTED`,
incluidos camber, toe, FVIC, RC, tracks y wheel-travel differential. No se
arrastra ni interpola el estado anterior.

`AxleRollSweepResult.performance` agrega wall time, estados escalares internos,
evaluaciones únicas de F, corner solves, cache hits, refinamientos de frontera,
tiempo de bracket y tiempo de `fzero`. Son diagnósticos de software, no métricas
físicas.

Los resultados fallidos conservan identity, target, status y diagnostics, pero
no publican estados o métricas aparentemente válidos. Los schemas v0.1–v0.5
no se modifican; `solveAxleHeave` adapta internamente el resultado general al
contrato histórico `AxleKinematicResult 0.4.0`.

# Contratos v0.7

Se mantienen structs funcionales para serialización MAT, App Designer futuro y
evaluación masiva. `ActuationGeometry` es opcional y no añade hardpoints
obligatorios a `DoubleWishboneGeometry`.

- `ActuationGeometry`: corner identity, tipo PUSHROD/PULLROD, attachment/body,
  eje de rocker canonicalizado, dos puntos rígidos del rocker, damper chassis,
  longitudes estáticas y metadata.
- `ActuationGeometryIdentity`: incluye toda geometría física y la decisión
  PUSHROD/PULLROD; no es un hash. `rocker.orientationMode` no pertenece a la
  identity porque es una ayuda de entrada: YZ y CUSTOM con el mismo eje
  canónico representan la misma física.
- `ActuationResult`: conserva el source result completo, theta unwrapped,
  puntos actuales, longitud/compresión, residual, conditioning y diagnostics.
- `ActuationSweepResult`: orden original, resultados completos, curvas básicas,
  continuation de rama y conteos de solves/estados omitidos.
- `ActuationAnalysis`: vista validada de un estado.
- `ActuationSweepAnalysis`: MR, installation ratio, angular gain, migración,
  stroke y rocker range.

Un failed result usa `NaN` para todos los puntos y valores derivados. La
identity no sustituye la validación del payload: se reconstruyen attachment,
rotación común, coeficientes, clasificación, candidatos, selección de rama,
damper length y conditioning.

La persistencia general continúa siendo MAT. Un `ActuationGeometry` es un
struct serializable y puede guardarse con `save`; los helpers históricos
`saveGeometryMat/loadGeometryMat` siguen deliberadamente limitados a
`DoubleWishboneGeometry`. No se introduce JSON.

La frontera de construcción es:

```matlab
actuation = fsd.model.createActuationGeometry( ...
    cornerGeometry, definition, inputUnit)
```

`inputUnit` es `"m"` o `"mm"`. `definition` contiene
`actuationType`, `suspensionAttachment.body/point`,
`rocker.orientationMode/axis/actuationRodPoint/damperPoint` y
`damper.chassisPoint`. Para YZ/XZ el axis direction se deriva del preset; CUSTOM
exige `axis.direction`. El modelo almacenado usa exclusivamente metros y el
frame `X_REAR_Y_RIGHT_Z_UP`.
