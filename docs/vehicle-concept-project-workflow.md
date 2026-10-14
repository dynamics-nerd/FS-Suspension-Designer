# v0.16 — Vehicle Concept & Engineering Project Workflow

## Contrato de implementación

Capa superior `fsd.project`, MATLAB/structs/MAT, independiente de App Designer.
Consume APIs públicas históricas; ninguna capa física depende de project.
No nuevas ecuaciones de suspensión/dinámica, neumáticos, optimizador o rules
engine. +X atrás/+Y derecha/+Z arriba y SI permanecen intactos.

Tres niveles separados: VehicleConcept registra datos progresivos; EngineeringScenario
declara acción, scope, targets y opciones; EngineeringResult conserva snapshots
de ejecución y payload nativo. EngineeringProject agrupa modelos opcionales,
escenarios y resultados, sin generar geometrías ni exigir cuatro esquinas.

## Concepto y estados

Parámetros numéricos conceptuales envuelven DesignParameter v0.11, sin reemplazar
sus roles ni disponibilidades. Un catálogo de cantidades conceptuales (no de
targets) cubre masas vehículo/piloto, batalla, vías, CG operativo XYZ, reparto
longitudinal, radios geométricos descargados/anchos y masas no suspendidas.
Units conversion por fábricas nativas; nunca deducir magnitud desde unidad.
Valores ausentes [], bounds explícitos, sin nominal implícito ni midpoint.

Rol KNOWN/FIXED/RANGE/FREE/TARGET/DERIVED/ASSUMED/RULE separado de provenance,
disponibilidad y confirmación. Confirmación DECLARED/VERIFIED/PENDING_CONFIRMATION
no convierte un supuesto en medición. VERIFIED requiere fuente KNOWN y referencia.
Estados superiores AVAILABLE/UNKNOWN/NOT_APPLICABLE/UNSUPPORTED/INVALID_INPUT/
DERIVABLE/PENDING_CONFIRMATION identifican causas; AVAILABLE_RANGE tiene bounds
pero no necesariamente valor escalar. Rangos ASSUMED mantienen provenance, aunque
su nominal v0.11 siga NOT_PROVIDED. Todo supuesto lleva nota; autor/fecha/referencia/
limitaciones cuando el caller los proporciona. TARGET no se utiliza como hecho.

Corrección V16-F-01: AVAILABLE describe una declaración almacenada, no su
elegibilidad física. RULE es un límite/requisito normativo, nunca la medición o
hipótesis física de esa cantidad, incluso con sourceKind KNOWN, referencia
VERIFIED y confirmation VERIFIED. Se conserva y valida el registro completo;
su selección física devuelve RULE_IS_NOT_A_PHYSICAL_INPUT. TARGET permanece
excluido; UNKNOWN, intervalos sin nominal y confirmación pendiente no aportan
un escalar. KNOWN/FIXED físicos y ASSUMED explícitos conservan el contrato nativo.
VERIFIED es respaldo declarado por el caller, no autenticación externa.

`massConvention` EXCLUDES_DRIVER/INCLUDES_DRIVER/UNSPECIFIED debe declararse.
EXCLUDES_DRIVER suma únicamente vehículo+piloto disponibles; INCLUDES_DRIVER no
añade piloto otra vez. UNSPECIFIED bloquea el total, no inventa inclusión.
Masa total es salida, no una entrada redundante. La suma es bookkeeping elemental
M=sum(m_i), ya definida por v0.9, no una aproximación dinámica ni otro modelo físico.
CG XYZ son del vehículo operativo completo: no se componen CG de piloto/chasis
sin posiciones explícitas. Masa total no permite inventar ninguna coordenada CG.

Arquitecturas FRONT/REAR son elecciones declaradas, inicialmente UNSELECTED.
Una elección no soportada puede registrarse pero bloquea su acción con diagnóstico.
Referencias normativas son metadatos identificados, no reglas ejecutadas ni
certificación; ROLE RULE usa el contrato estructurado v0.11.

## Derivación explícita y modelos existentes

deriveVehicleConcept registra inputs/dependencias/provenance y resultados disponibles.
Con ambas masas suficientes puede producir total sin inventar g ni dimensiones.
Para preparar VehicleParameters v0.9 se requieren además dimensiones, gravedad
m/s² y operatingConfiguration explícitos. Contactos conceptuales sólo cuando se
declara CONCEPTUAL_HORIZONTAL; EXPLICIT usa cuatro contactos proporcionados.
No son geometrías double-wishbone seed ni hardpoints nuevos. Sin autorización
de contactos/modelo se conservan parámetros y dependencias ausentes.

createVehicleParameters deriva CG X de fracción longitudinal cuando procede,
comprueba fracciones/CG contradictorios y conserva Y/Z desconocidos. El modelo
nativo preserva hipótesis de contactos/provenance. analyzeStaticVehicleLoads
produce cargas de eje/familia/corner únicamente bajo su contrato. UNDERDETERMINED
es ausencia de cuarta ecuación, no reparto 50/50 implícito; cualquier closure se
declara. Normalizar una carga de eje con W existente da fracción descriptiva,
no un objetivo de rendimiento. No resolver equilibrio de cuatro esquinas por defecto.

Rangos: selectConceptValues sólo admite elecciones explícitas dentro de intervalos,
mantiene el intervalo/provenance y etiqueta el punto escogido ASSUMED. Evaluar
extremos declarados es comparación de escenarios discretos, no robustez continua.
Una derivación conserva concepto/opciones originales; al cambiar inputs se comprueba
compatibilidad, no se reetiqueta la evidencia vieja como cálculo del concepto nuevo.

selectConceptValues no acepta intervalos RULE: elegir un número dentro de un
límite no lo convierte en una hipótesis física. Los IDs conceptuales son únicos:
v0.16 no almacena simultáneamente RULE y dato físico con el mismo ID. Para el
caso de una masa normativa y otra física se debe reemplazar explícitamente el
parámetro mediante createConceptParameter/createVehicleConcept y revisar el
proyecto; la configuración anterior se conserva fuera de esa nueva revisión.
No hay promoción automática ni nuevo esquema de múltiples cantidades por ID.

El gate común se aplica a masas, dimensiones, CG, fracciones, masas no suspendidas
y a cualquier conceptDependency explícita (incluidas dimensiones de rueda).
Los datos opcionales excluidos permanecen desconocidos en el modelo nativo;
no bloquean métricas independientes de ellos. CG longitudinal sin dato físico
ni fracción física impide readiness de cargas de eje. Dependencias obligatorias
ausentes, como masa, producen MISSING_DATA y bloquean runEngineeringScenario.
La preparación registra ID y causa semántica; no ejecuta cargas ni búsquedas.

ConceptDerivation reconstruye dependencias, contexto y valores del concepto
original. DERIVED escalar externo conserva la referencia declarada exigida
por v0.11: no es una derivación ejecutable ni una prueba de autenticidad.
Los records de derivación internos sí se reconstruyen y los contextos obsoletos
se rechazan; no se añade aquí un intérprete de referencias externas.

## Recursos, escenarios y readiness

Recursos nativos por corner: geometries, actuations, mechanicals; steering FRONT
cuando se proporciona. Modelos se validan y asociaciones existentes deben ser
coherentes. No se crea FR a partir de FL ni se toma geometría desde una identity.
Cambios de modelos relacionados deben ser explícitos/atómicos; resultados históricos
conservan sus propios snapshots y no se mutan al reemplazar recursos actuales.

Escenarios: STATIC_GEOMETRY, BUMP, ROLL, RACK, ACTUATION, MECHANICAL,
TARGET_EVALUATION, STATIC_LOADS y cuatro síntesis CORNER/AXLE/STEERING/ACTUATION.
GLOBAL_STATIC existe como modelo histórico v0.10 pero no se ejecuta automáticamente
ni se rellena con cuatro esquinas/paths/tires ausentes. Acciones no adaptadas son
UNSUPPORTED, no capacidades físicas ficticias.

prepareEngineeringScenario/designReadiness sólo comprueban contratos y
prerrequisitos: READY/MISSING_DATA/INVALID_INPUT/UNSUPPORTED/BLOCKED_BY_DEPENDENCY,
con dependencias concretas y avisos de fidelidad. No BUMP/ROLL/RACK/rocker/search.
Factories y validadores algebraicos nativos son admisibles; READY no garantiza
convergencia, cobertura de targets, límites físicos o manufacturing feasibility.
Grids/velocidades/heave/rack context se declaran en SI; sólo defaults numéricos
nativos, nunca valores típicos FS. Opción pura de búsqueda se expone mediante
searchSettings: wrapper del searchOptions existente, no otro algoritmo.

Las cuatro síntesis llaman create*DesignSpace y run*InverseSearch públicos.
No duplican builders, normalización, polling, score o políticas HARD/SOFT.
specificationSources usa designMetricCatalog y la especificación original para
identificar aliases/familias/scopes y dependencias. No segundo catálogo de métricas.
Una spec de otra familia/plan/corner se diagnostica, no se proyecta para ocultarla.

Orígenes de target: USER_DEFINED/DECLARED_REFERENCE/SUPPORTED_MODEL/ASSUMED/
PENDING_JUSTIFICATION, con referencia declarada y advertencias. Son metadatos de
origen, no una certificación de su idoneidad. No generar camber gain/MR/grip targets
desde masa, batalla, vías, CG o radio. Los futuros modelos de prestaciones,
neumáticos y objetivos permitirán justificar esa generación en otra milestone.

## Revisiones, resultados y persistencia

Structs consumidores0.16.0 con identities canónicas completas sin hash. Orden de
parámetros/recursos/escenarios se canonicaliza por ID/corner; planes/spec conservan
el orden significativo nativo. reviseEngineeringProject devuelve otra revisión;
un no-op no crea una revisión ficticia. Incorporar resultados no cambia la
configuración física de esa revisión. No sustituye Git ni implementa branches internos.

Resultado liga proyecto/revisión/concepto/escenario originales, recursos consumidos,
plan/opciones/spec, motor/contrato y payload nativo. Validación reconstituye inputs
y verifica payloads/assessments históricos sin solves nuevos. Compatibilidad actual
usa dependencias selectivas: masa no invalida BUMP/síntesis cinemática que no la usa;
seed, targets u opciones relevantes sí. Dependencias conceptuales justificativas
adicionales se declaran, nunca se infieren. Concept revision antigua sigue visible
al reutilizar evidencia: REUSABLE_DEPENDENCIES no es nueva ejecución CURRENT.

Datos no relevantes y nombres de presentación no invalidan indiscriminadamente
la física. Identidades físicas históricas pueden incluir datos contextuales cuya
ecuación final no usa directamente: se respetan esos contratos, sin reparentar
payloads ni fabricar nuevas identities. No autenticidad criptográfica.

MAT contiene encabezado de archivo versionado y proyecto completo. Guardar valida;
sobrescritura requiere opción explícita. Cargar valida todos los registros y conserva
estatus obsoletos respecto a la revisión actual. MAT físicos previos permanecen en
sus APIs; no se migran a proyectos inventando metadata. Usar MAT de fuentes fiables:
no se promete sandbox contra deserialización de objetos MATLAB maliciosos.

Los validadores reconstruyen también la elegibilidad por rol original. La
evidencia antigua que usaba RULE como entrada física se rechaza en derivación,
resultado, asociación, compatibilidad y save/load, con la causa semántica en
la cadena de diagnóstico. No se migra ni se reetiqueta para hacerla válida.
Una evidencia genuina de física independiente sigue REUSABLE_DEPENDENCIES
ante cambios de RULE/masa/metadatos no consumidos. STATIC_LOADS conserva su
contexto completo nativo y puede ser STALE al cambiar ese contexto.

## Limitaciones y decisiones abiertas

La implementación y verificación final se registran en docs/v0.16-validation.md;
ese informe distingue comprobaciones ejecutadas y pendientes. Datos de ejemplos heredados
ASSUMED ilustran flujo, no son mediciones de un monoplaza real ni semillas generadas
por VehicleConcept. Se identifica cualquier ejecución externa usada para preparar
una referencia de benchmark, fuera del presupuesto del escenario.

OPEN DECISION: entradas/CG/arquitecturas/targets/gravedad/contactos/cierres reales,
confirmación experimental, incertidumbre continua, modelos de prestaciones y
neumáticos para targets, fabricación/CAD/normativa/Adams/UI. Sin v0.17.
Observaciones LOW preservadas: V14-OBS-01 título/exponente Ackermann,
V15-OBS-01 texto AXLE en diagnóstico de actuación, V15-OBS-02 ejes sobre intervalos
extremadamente pequeños. No refactor gráfico histórico para resolverlas aquí.

## API y uso reproducible

Las funciones públicas residen en `fsd.project`; listadas también en `fsd.Contents`:

| Operación | API |
|---|---|
| Cantidades/estados | conceptParameterCatalog, createConceptParameter, validateConceptParameter |
| Concepto | createVehicleConcept, validateVehicleConcept, deriveVehicleConcept, validateConceptDerivation, selectConceptValues |
| Configuración | createEngineeringScenario, validateEngineeringScenario, createEngineeringProject, validateEngineeringProject, reviseEngineeringProject |
| Preparación | specificationSources, designReadiness, prepareEngineeringScenario |
| Ejecución/evidencia | runEngineeringScenario, validateEngineeringResult, resultCompatibility, attachEngineeringResult |
| MAT | saveEngineeringProject, loadEngineeringProject |

`fsd.synthesis.searchSettings(input,variableCount)` expone únicamente la
normalización histórica, sin ejecutar el controlador. No cambian APIs anteriores.

```matlab
setupProject;
c = fsd.project.createVehicleConcept(struct('id',"MY_PROJECT"));
p = fsd.project.createEngineeringProject(struct('concept',c));
r = fsd.project.designReadiness(p); % doce capacidades; sin solves/search
fsd.project.saveEngineeringProject(p,'my-project.mat'); % no overwrite por defecto
p2 = fsd.project.loadEngineeringProject('my-project.mat');
```

Campos exactos de Scenario.definition: id/name/description/engine/scope,
plan/options/specification/symmetryLinks/targetOrigins/conceptDependencies/inputs.
Plan de BUMP/ACT: travel_m + solverOptions nativas opcionales; MECH exige además
wheelVelocity_m_per_s explícita. ROLL: angles_rad/axleHeave_m + solverOptions;
RACK: travel_m/wheelTravel_m + solverOptions. Síntesis: plan nativo completo,
opciones del controlador en options, spec original y seeds en resources del
proyecto; nada se deduce del Concept. TARGET_EVALUATION recibe inputs.candidate
completo previamente resuelto. Sus fuentes explícitas son el contexto consumido,
no se reemplazan automáticamente por los seeds actuales del registro del proyecto.

STATIC_LOADS usa plan como opciones físicas del concepto: gravity_mps2,
gravitySourceKind/gravitySourceNote, operatingConfiguration, contactPolicy,
contactPoints_m/contactSourceKind/contactSourceNote, loadCaseDefinition y
loadCaseUnits (force/crossweight). Gravedad/contactos ya son SI explícito;
no se reparten conversiones de aceleración por el core. READY promete inputs
para cargas de eje; familia/corners dependen además de CG lateral y closure
nativos. Leer siempre el status del payload, no convertir READY en cuatro
cargas conocidas. derive.status describe preparación, cada valor tiene su
propio status y la carga conserva el diagnóstico completo nativo.

TargetOrigins es cell de registros targetId/kind/reference/note. Origen ausente
da diagnóstico PENDING_JUSTIFICATION; referencias y SUPPORTED_MODEL son
declaraciones del caller, no verificaciones automáticas ni recomendaciones.
conceptDependencies declara cantidades adicionales usadas para justificar
escenarios/targets; ausencia bloquea, modificación vuelve obsoleta la evidencia.
Arquitecturas elegidas se contrastan con el adapter/actuationType; UNSELECTED
no inventa una elección porque el recurso nativo ya declara su arquitectura.

Readiness sin scenarioId examina los escenarios registrados; si no existen,
devuelve doce capacidades prototipo FL/FRONT/VEHICLE explícitamente identificadas
por scope, no la afirmación de disponer de cuatro esquinas. Readiness valida
configuración, no el ledger histórico; para validar TODO usar validateEngineeringProject.
No consulta licencia/toolbox ni garantiza convergencia/coverage/HARD.

La capa usa contratos físicos concretos, no niveles de fidelidad inventados:

| Acción | Base física existente y límite |
|---|---|
| STATIC_GEOMETRY | Geometría nominal; longitudes elementales, no movimiento |
| BUMP/corner synthesis | Cierre DW rígido v0.2/0.3; sin compliance |
| ROLL/axle synthesis | Eje y cierre de carretera v0.6; no dinámica de chasis |
| RACK/steering synthesis | Rack rígido FRONT v0.5; no columna/pinion/compliance |
| ACT/actuation synthesis | Rod/rocker rígidos v0.7; no dimensionado estructural |
| MECH | Coilover/path v0.8; derivadas/quality/límites nativos, no neumático dinámico |
| STATIC_LOADS | Balances/familia/cierre v0.9; no pose acoplada de chasis |
| TARGET_EVALUATION | Comparación v0.11 sobre evidencia explícita, no forwards |

RACK en este adapter exige también corners registrados coherentes, aunque el
SteeringSystem nativo los contiene; no se extraen seeds implícitamente ni se
fabrica la esquina ausente. Datos experimentales sólo cuando los inputs/origin
los declaran; no se presupone un dataset medido ni validación CAD/estructural.
Los radios/anchos conceptuales se almacenan: no son leyes de neumático conectadas.
Los resultados preservan gap/NaN y estado de calidad aun con preparación READY.

Errores de preparación reconocidos se clasifican con su ID/mensaje original;
errores desconocidos/de infraestructura se propagan. Ejecución no disfraza
excepciones como infeasibilidad. Los fallos físicos válidos permanecen en los
payloads nativos y sus assessments, incluidos NaN/gaps y falta de ganador.

Tiempo de ejecución es informativo, no fingerprint. Validadores reconstruyen
geometrías/controles/analysis/assessment; ignores de elapsedTime sólo evitan
comparar cronómetros de recomputaciones algebraicas. No firma criptográfica,
garantía experimental ni detección de una historia alternativa completamente
reconstruida y físicamente coherente. No identidad se acepta como sustituto
de validar payload. Revisión/contrato/software del resultado nunca se reescriben.
