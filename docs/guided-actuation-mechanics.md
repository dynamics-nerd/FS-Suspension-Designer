# v0.20 — Guided actuation and mechanics

## Scope and authority

The existing v0.7/v0.8/v0.15 models remain authoritative. The guided flow selects
an explicit registered corner, declares PUSHROD/PULLROD and UPRIGHT/UCA/LCA,
constructs native actuation/optional coilover resources, executes native analysis
and actuation synthesis, compares stored evidence and explicitly adopts a candidate.
Suspension geometry stays fixed. No structural forces, Direct Acting, fabrication,
advanced hydraulics or v0.21 physics are introduced.

## Operation/result contract (defined before implementation)

All new actions use the existing Controller operation ID, epoch, ownership,
canonical payload validation and owner-authoritative semantic reconstruction.
The shared operationBody executes declarations on dispatch and reconstructs them
on receipt, substituting only already validated native records at runScenario.
Receipt never performs a new BUMP, rocker solve or inverse search.

| Action | Owner arguments | Outcome / policy | Required correspondence |
|---|---|---|---|
| ACTUATION_CONFIG | cornerId, native actuation definition/unit, optional mechanical definition/units | Revised resources, no result / APPEND | Exact selected registered geometry; atomic replacement of actuation and its mechanical association; exact other resources |
| ACTUATION_RUN | cornerId, engine ACTUATION or MECHANICAL, native SI plan, resultId | New native scenario/result / APPEND | Engine, corner, geometry, actuation/mechanics, full plan/options, result ID and execution snapshot |
| SPECIFICATION | Native ACTUATION_SYNTHESIS declaration | Scenario/readiness / APPEND (existing action) | Complete specification, origins, controls, scope and configuration |
| SYNTHESIS | scenarioId, resultId | Native ACTUATION_SYNTHESIS result / APPEND (existing action) | Full owner scenario and snapshot; original complete native validation |
| ACTUATION_ADOPT | stored resultId, candidate index | Revised resources, no result / APPEND | Compatible actual ACTUATION_SYNTHESIS result; eligible selected record; unchanged suspension; exact candidate actuation/mechanics |

workerRequest retains the adoption parent only; the owner retains its complete
ledger. Reduced projects are not substituted for the owner's history. Semantic
rejection is atomic under the v0.19 RF-01/RF-02/RF-03 guards. SAVE/LOAD preserve
their current complete-content checks. No new physical or storage schema.

## Physical and numerical methods

See [actuation geometry](actuation-geometry-synthesis.md) and
[coilover mechanics](spring-damper-wheel-rate.md) for equations, units, algorithms,
derivative safeguards and assumptions. In particular c=L0-L, signed MR=dc/dz,
Fw=Fs*MR and Kw=k*MR^2+Fs*dMR/dz retain the native validity gates. Velocities are
explicit prescribed inputs, not inferred dynamics. Limits absent means UNKNOWN.
Rocker axis point is a canonical line coordinate, not a bearing location.

The UI converts lengths/angles at boundaries only. Missing required physical
values stay blank and fail configuration/readiness; optional bounds stay absent.
Native metadata preserves declared source/provenance. No example is loaded
implicitly. The native factories and evaluators, rather than callbacks, own all
engineering calculations. Choosing existing factories instead of a second model
preserves historical numerical behavior and its independent references. Historical
motivations not recorded in the linked contracts remain pending reconstruction.

## State, lifecycle and validation

Drafts must be applied before execution or saving. Stored results retain their
original models, frames and revisions and show canonical current compatibility.
Adoption uses one project revision and retains historical evidence. Changing an
actuation/mechanical resource does not change BUMP geometry. Changed dependencies
can make mechanics/synthesis STALE. No history or candidate is silently removed.

Use the existing process execution and cooperative conversion stages, explicit
worker/synchronous choice, cancellation and single-writer MAT publication.
Long operations are permitted; no universal time, memory or project-size cap.
Measure representative new integrated flows; investigate severe regressions before
expanding that flow. Do not weaken precision, validators or persistence for speed.

Tests must cover configuration without solves; SI boundary equivalence; real
native analysis; coherent adoption and unchanged suspension; canonical but wrong
response substitutions; selective STALE; exact MAT; actual process execution,
cancellation and native UI. Actual outcomes belong in [v0.20 validation](v0.20-validation.md).

## Interfaces públicas y modelo persistido

```matlab
[project, actuation, mechanical] = fsd.project.configureActuationResources( ...
    project, cornerId, definition, lengthUnit, mechanicalDefinition, units);
project = fsd.project.adoptActuationCandidate(project, storedResult, index);
```

La primera API exige exactamente una geometría registrada para el corner. Usa
`createActuationGeometry` y, cuando se declara, `createSpringDamperModel`; aplica
ambos recursos en una sola revisión validada. `mechanicalDefinition=[]` significa
eliminar explícitamente la mecánica anterior de esa esquina. Un error no publica
un proyecto parcial. La adopción exige el resultado **íntegro y exacto del ledger**,
compatibilidad actual/reutilizable, índice entero existente y candidato elegible.
Se copia su actuación y su mecánica exactas, no se reconstruye una aproximación
desde los números mostrados. La geometría completa debe seguir siendo idéntica.
No se modifican otros corners, escenarios, resultados ni bindings de construcción.
Una aplicación idéntica puede ser no-op; una configuración diferente usa la revisión
canónica. Descripción/procedencia e identidad física siguen dominios separados.

Se reutilizan `ActuationGeometry`0.7, `SpringDamperModel`0.8, síntesis0.15 y
`EngineeringProject/Scenario/Result`0.16. El software productor es0.20.0; se amplían
únicamente las listas de versiones admitidas de resultados/fuentes. El almacenamiento
sigue0.19 (`FSD_VALUE_GRAPH_V1`, variables por registro) o el formato clásico cuando
corresponde. No hay migración silenciosa ni un segundo fichero de interfaz.
Todos los escenarios, modelos, procedencias, opciones y resultados se guardan.
Los borradores no aplicados y la cámara/selección de controles no son datos MAT.

## Recorrido de uso y unidades

1. Construir una geometría con el flujo existente o abrir un MAT válido que la
   contenga. Elegir su corner en Actuation. No se carga un ejemplo implícitamente.
2. Configuration: elegir PUSHROD/PULLROD y UPRIGHT/UCA/LCA. Declarar los seis roles
   mostrados: attachment, punto de la línea del eje, dirección, dos puntos rígidos
   del rocker y chassis del damper. XYZ se introduce en mm; dirección adimensional.
   YZ_PLANE implica +X, XZ_PLANE implica +Y. Si se aporta una dirección contraria
   al preset, la fábrica la rechaza; CUSTOM requiere vector y procedencia explícitos.
   Sin recurso previo, arquitectura/body/orientación/ley quedan UNSELECTED: deben
   elegirse explícitamente y no se heredan de otra esquina ni de otro proyecto.
3. Activar opcionalmente COILOVER. Declarar k en N/mm, longitudes/precarga en mm,
   damping lineal asimétrico en N/(mm/s), o ambas tablas velocidad-magnitud [mm/s,N].
   Cada tabla tiene al menos dos filas, empieza exactamente en [0,0] y velocidades
   crecientes; la fábrica controla pasividad/dominio. No se inserta la fila cero.
   Para tablas, las columnas source de COMPRESSION_COEFFICIENT/REBOUND_COEFFICIENT
   documentan las ramas y su valor numérico no se utiliza. Se pueden añadir/eliminar
   filas. Límites opcionales vacíos permanecen desconocidos, no se estiman del nominal.
4. Cada entrada física utilizada exige KNOWN/ASSUMED/DERIVED y una nota de fuente.
   La UI conserva otras claves de metadata existentes. La procedencia de parámetros
   se guarda en `metadata.parameterProvenance`, indexada por el ID de fila; no cambia
   la ecuación ni convierte ASSUMED en KNOWN. Apply valida y registra atómicamente.
5. Analysis: declarar muestras ordenadas de recorrido en mm. ACTUATION no requiere
   velocidad; MECHANICAL exige velocidad prescrita explícita, escalar o por muestra,
   en mm/s. Cero se escribe para reposo. Check aplica escenario/readiness sin solves;
   Run ejecuta. No se densifica ni recorta el grid. Las opciones BUMP nativas existentes
   se conservan aunque esta vista no las expone como un editor genérico.
6. Synthesis: declarar targets, variables/bounds y restricciones nominales. Las tablas
   admiten listas numéricas; las unidades son explícitas por fila. Apply muestra
   readiness; Run ejecuta el escenario `UI_ACT_SEARCH_<corner>`. El plan de texto
   se comparte con Analysis, pero cada escenario aplicado conserva su propio plan.
   Al recuperar la vista se carga el plan de esa síntesis si existe; en su ausencia,
   un escenario `UI_ACTUATION_*`/`UI_MECHANICAL_*` del corner (preferencia al motor
   seleccionado). No se reconstruye un plan desde las curvas calculadas.
7. Evidence: elegir resultado, candidato y muestra guardados. Se muestran seed y
   candidato seleccionado, scores, elegibilidad, HARD, clasificación y motivos.
   Curvas de compresión/longitud en mm, theta unwrapped en grados, MR firmado e
   installation adimensionales, fuerzas en N y wheel rates total/elástico/geométrico
   en N/mm. Ejes 3D en mm. Datos ausentes conservan NaN; una pose/candidato inválido
   limpia la presentación en vez de sustituirlo. La validez por muestra y los límites
   nativos se muestran junto a los fallos y la compatibilidad de revisión.
8. Adopt candidate exige confirmación explícita. Sólo se habilita para evidencia
   compatible y elegible. La adopción deja los resultados originales visibles como
   STALE cuando cambian sus dependencias; un BUMP geométrico independiente permanece
   reutilizable. Guardar y abrir desde Project usa el mismo MAT completo del proyecto.

## Algoritmos reutilizados y límites de integración

El BUMP de cinco restricciones usa el solver/continuation histórico. Para el rocker,
el attachment móvil procede de la pose nativa de upright o del brazo rígido; la
intersección círculo–esfera obtiene las raíces y la continuación elige theta próxima
a la anterior. Ambos puntos del rocker rotan con la misma R(u,theta). Tangencia,
no-intersection, underconstrained y parada tras fallo mantienen sus estados nativos.
Las derivadas de MR y su curvatura usan la política local cuadrática/F01-1 histórica;
no se deriva en pantalla ni se sustituye Kw total por k*MR² cuando falta curvatura.
El muelle compression-only conserva Fs=k*max(preload+c,0); unseating, transición y
coil bind conservan sus gates. El damper lineal o interpolación lineal de tablas
mantiene el signo resistente y no extrapola fuera del dominio tabulado.
Las ecuaciones completas, regímenes y tolerancias figuran en los contratos enlazados.

La búsqueda usa `createActuationDesignSpace` y `runActuationInverseSearch` con
`boundedDirectSearch`: coordenadas normalizadas, preflight HARD, construcción nueva,
BUMP/actuación/mecánica nativos y assessment original. No optimizador nuevo ni
global guarantee. La dirección del eje está fija; el punto canónico sólo tiene dos
DOFs independientes, según el contrato0.15. No se optimizan k/precarga: sus bindings
SPRING_RATE/SPRING_PRELOAD sólo expresan restricciones conocidas FIXED/RANGE.
FREE mecánico se rechaza. Las opciones expuestas son maxEvaluations, maxIterations,
initialStep, minimumStep, stepReduction, stopAtScore y scoreImprovement; vacías usan
defaults numéricos históricos. Semillas/opciones nativas no expuestas se conservan.
No se genera un target ni escala/peso/justificación automáticamente.

Las filas sin editar reutilizan el objeto nativo exacto (evita roundoff y pérdida
de metadata). Al editar se conservan anotaciones no expuestas y se convierten sus
unidades correctamente. Cambiar la métrica de un target exige ID nuevo para evitar
reinterpretar incertidumbres de otra magnitud. Orígenes ausentes de targets antiguos
siguen ausentes; un target nuevo/editado se declara USER_DEFINED, no modelo derivado.
El editor carga sólo su escenario UI; las otras especificaciones permanecen en el
proyecto y se usan mediante las APIs. No pretende editar cualquier contrato futuro.

Las fuerzas mostradas son axiales del coilover y resistencias equivalentes a rueda,
no fuerzas internas del rod, cargas normales de neumático o equilibrio del vehículo.
No se añaden modelos estructurales, fabricación, fatiga, pandeo, histéresis, hidráulica
avanzada, Direct Acting, ARB ni integración conjunta de cuatro esquinas. Los límites
y costes históricos de validación/serialización siguen vigentes; ninguna prueba de
un historial pequeño demuestra capacidad ilimitada ni ausencia de todas las fugas.

## Decisiones, alternativas y evidencia reproducible

[GAM-001…006](decisions.md) registra las decisiones nuevas y alternativas descartadas;
no atribuye motivaciones retrospectivas. El ejemplo
`guidedActuationMechanicsExample` crea cuatro resultados desde datos ASSUMED, compara
una referencia nativa independiente de +5mm chassis-Y y busca tres evaluaciones antes
de adoptar. Su referencia valida integración de APIs, no es una referencia experimental
independiente. Los oráculos independientes para las ecuaciones son los tests históricos
de cinemática/energía/curvatura, conservados y repetidos en la validación indicada.

## Dependencias, errores y ejecución

MATLAB R2026b es el entorno verificado. Se conserva Optimization Toolbox para el
BUMP histórico (`fsolve`); el cierre de rocker es analítico y la búsqueda directa
no añade otro toolbox de optimización. Parallel Computing Toolbox sólo se necesita
para el process worker, no para el modo síncrono. No Global Optimization, Simscape,
servicio externo ni otro lenguaje añadidos. Un toolbox instalado no equivale a un
modelo físico disponible. Los modelos de neumáticos/eventos/ARB siguen su roadmap.

| Situación | Comportamiento |
|---|---|
| Geometría ausente o ambigua | Configuración rechazada; elegir/build/load de geometría registrada |
| Dato físico requerido vacío/no finito o sin fuente | Error con ID de parámetro, proyecto sin aplicar parcialmente |
| Límites físicos opcionales ausentes | Se conservan vacíos; evaluación UNKNOWN, ninguna aprobación de seguridad |
| Modelo/plan/spec incompleto o no soportado | Readiness nativa y diagnóstico; no reemplazo por datos ilustrativos |
| Fallo de cierre/derivadas/dominio de damper | Estado/fallo/NaN nativos y gaps visibles; no extrapolación ni clipping silencioso |
| Respuesta canónica de otro motor/grid/opciones/candidato | Rechazo semántico RF-03, owner/historial intactos |
| Edición durante ejecución | Epoch invalida retorno; no aplicación parcial, estado STALE |
| Cancelación | Mecanismo existente, esperar fin/limpieza antes de otra operación o cierre |
| Sin worker con Async activo | Elección explícita; un error al iniciar no cambia a síncrono por su cuenta |
| Guardado sobre ruta existente | Confirmación/overwrite explícitos de Project; ejemplo exige destino nuevo |

La cancelación y los callbacks cooperativos no convierten todo el replay/merge
canónico en una operación de latencia garantizada. Una ejecución síncrona puede
ocupar el hilo gráfico. Los costes incluyen preparación, validación, transporte y
recepción, no sólo fsolve; se informan por separado cuando se mide el worker.

### Referencia del editor de targets

`fsd.model.designMetricCatalog` es la autoridad; la síntesis0.15 admite estas
familias reconstructibles para la esquina fija, con x = WHEEL_TRAVEL [mm]:

| Familia | Metric ID | Unidad de valor en la vista |
|---|---|---|
| ACTUATION | DAMPER_COMPRESSION | mm |
| ACTUATION | MOTION_RATIO / INSTALLATION_RATIO |1|
| ACTUATION | ROCKER_ANGLE |deg|
| MECHANICAL | DAMPER_COMPRESSION / MOTION_RATIO / INSTALLATION_RATIO |mm /1 /1|
| MECHANICAL | SPRING_AXIAL_FORCE / SPRING_WHEEL_RESISTANCE |N|
| MECHANICAL | TANGENT_WHEEL_RATE |N/mm|
| BUMP | CAMBER / TOE / BUMP_STEER / CASTER / KPI |deg|

Source ID es un alias estable declarado por el usuario, por ejemplo ACT_FL,
MECH_FL o BUMP_FL; el espacio nativo registra los alias solicitados por familia,
no un resultado externo arbitrario. Las familias/condiciones no reconstructibles
se rechazan. El BUMP de suspensión fija no se convierte en una variable de actuación.
No toda magnitud que puede representarse es un target disponible: por ejemplo,
las fuerzas de damper se muestran, pero no se añade una métrica de optimización.
Los tipos POINT_TARGET/CURVE_TARGET y bandas, HARD/SOFT, tolerancias y escalas
mantienen las reglas del [contrato de targets](design-requirements-target-evaluation.md).
