# v0.12 — Inverse Suspension Synthesis

Capa explícita `fsd.synthesis` sobre las APIs existentes. MATLAB R2025b,
structs serializables/MAT, una esquina con seed válido obligatorio. No altera
ecuaciones de suspensión, convenciones ni el evaluador v0.11. +X atrás,
+Y derecha, +Z arriba; metros/radianes internos.

## APIs y responsabilidades

```matlab
space = fsd.synthesis.createDesignSpace(seed, specification, plan);
fsd.synthesis.validateDesignSpace(space);
u = fsd.synthesis.normalizeVariables(space, x_m);
x_m = fsd.synthesis.denormalizeVariables(space, u);
[geometry, changes] = fsd.synthesis.buildCandidateGeometry(space, x_m);
evaluation = fsd.synthesis.evaluateSynthesisCandidate(space, u, evaluationId);
result = fsd.synthesis.runInverseSearch(space, options);
fsd.synthesis.validateSynthesisEvaluation(evaluation, space);
fsd.synthesis.validateSynthesisResult(result);
comparison = fsd.synthesis.compareSynthesisCandidates(result, indices);
figures = fsd.synthesis.plotSynthesisResult(result, indices);
```

`boundedDirectSearch(initial,active,options,evaluator,keyFunction)` es el
controlador matemático verificable aparte del mecanismo. Callback
`evaluator(u,id)` devuelve struct con `eligible` lógico, `score` no negativo
finito o NaN y `reason`. La clave representa igualdad exacta del problema
evaluado. No es un solver físico ni una interfaz de expresiones de ingeniería.
Los callbacks sólo existen en ejecución; el resultado guarda datos, no handles.

Flujo: spec + seed + plan → espacio validado → coordenadas autorizadas →
fábrica/validadores geométricos → solveBumpSweep → analyzeBumpSweep →
DesignCandidate canónico → evaluateDesignCandidate v0.11 → controlador →
registros de todas las evaluaciones y todos los intentos → comparación/plots.
Sólo el coordinador ejecuta solves. Validadores, comparación y plots verifican
fuentes sin solves; no se cambia el DAG histórico.

## Variables, FIXED y bounds

Reutiliza **todos** los parámetros FREE/RANGE de la especificación; no hay
selección oculta. Binding HARDPOINT_X/Y/Z, scope HARDPOINT de la esquina seed,
unidad canónica m, bounds finitos explícitos. Únicos puntos modificables:
UCA_FWD_CHASSIS, UCA_AFT_CHASSIS, LCA_FWD_CHASSIS, LCA_AFT_CHASSIS. Se pueden
combinar varias componentes; no se permiten bindings duplicados. No se habilitan
outboards, tie rods/rack, actuación, rocker, damper ni wheel axis.

Cada variable conserva ID, corner, hardpoint, componente, fila/columna reales,
initial/lower/upper, DesignParameter íntegro/provenance y seedIdentity.
Si el parámetro tiene value, debe coincidir exactamente con el seed; si está
vacío, initial procede explícitamente de la coordenada del seed, no de un preset.
El seed debe estar dentro de cada intervalo; span debe ser representable.
Otros parámetros vinculados FIXED/FREE/RANGE requieren binding HP de esta esquina.
Inputs conceptuales no vinculados/KNOWN/ASSUMED pueden seguir en la spec, sin
convertirse en restricciones físicas certificadas.

FIXED con binding conserva su contrato de tolerancia v0.11 al comprobar el seed.
Una coordenada marcada FIXED o un HARDPOINT_FIXED HARD no puede ser variable
móvil, **aunque la tolerancia no sea cero**: política deliberadamente más
conservadora de autorización de mutación, no cambio de aceptación v0.11.
Los puntos no seleccionados quedan bit-idénticos; no hay transformaciones
indirectas. HARDPOINT_FIXED SOFT sigue siendo una preferencia nominal.
AXIS_ALIGNED_BOX se evalúa explícitamente con v0.11 sobre cada geometría;
un intento exterior se conserva como HARD rechazado, no se hace clipping físico.
La búsqueda sólo clippea **u** a su box de variables cerrado.

## Normalización

Para span positivo: `u=(x-l)/(h-l)`, `x=l+u*(h-l)`; u en [0,1]. Endpoints
exactos, seed preservado bit a bit al decodificar su u. Span cero: u=0,
x=l=h, eje inactivo; cualquier u no cero se rechaza. No se divide por cero.
La reversibilidad de coordenadas interiores tiene la resolución de double:
si span es muy pequeño respecto al origen, el error de u es del orden de
`eps(max(abs([l,h])))/(h-l)`. No se promete precisión adimensional imposible.
Pruebas cubren spans 1e-12 a 1e6 m y escalas mezcladas; son stress tests
numéricos, **no dimensiones de vehículos recomendadas**.

## Reconstrucción y fuentes

El builder copia XYZ/provenance y cambia sólo las coordenadas autorizadas,
reconstruyendo con createDoubleWishboneGeometry. Conectividad/upright/wheel
canónicos proceden de la fábrica; nombres/frame/metadata del seed se conservan.
Coordenadas cambiadas se registran DERIVED con la referencia al parámetro y
su sourceKind/sourceNote originales. No se etiquetan como mediciones KNOWN.
Identidad física nueva de geometryIdentity, sin hash ni caché de identidad vieja.
Wheel axis no seleccionado se copia exactamente del seed tras la fábrica:
no se permite que una segunda normalización cambie su representación por
roundoff; la validación unitaria histórica sigue aplicándose sin relajación.

Validación existente: finitud, IDs, pivotes distintos, links no nulos, upright
no collineal y referencias de rueda. Además, se rechaza un triángulo de brazo
collineal mediante el mismo presupuesto dimensional AbsTol/RelTol histórico
usado para áreas del upright. Esto no prueba resistencia, CAD ni fabricación.

Plan explícito: `travel_m` vector finito estrictamente monótono (o scalar),
`solverOptions` opcional validado por solverSettings. No se extrapola el plan
para cubrir automáticamente un target: missing coverage queda explícita.
El preflight sólo admite **CAMBER, TOE, BUMP_STEER, CASTER y KPI desde BUMP**,
scope de la esquina seed. Todos los tipos de comparación v0.11 son reutilizados.
RACK/ROLL/ACTUATION/MECHANICAL/STATIC_LOADS/GLOBAL_STATIC y demás métricas se
rechazan antes de buscar con target ID y análisis/métrica faltante. Un target
con requiredSourceIdentity fijada se rechaza: no se relaja para cambiar geometría.

Por geometría única válida se resuelve exactamente un sweep nuevo; source IDs
BUMP distintos son aliases explícitos del mismo plan/modelo/evidencia nativa.
Se conservan sweep completo, estados, diagnostics, staticToe, gaps y análisis.
No se acepta un candidato externo con fuentes seed para regenerar dependencias.
La primera implementación construye sólo fuentes BUMP y ninguna fuente obsoleta
de las otras familias. Sus futuros adapters necesitarán reconstrucción propia.

## Calidad y rama: guard local adicional

El solver mantiene su continuation nativa desde el estado estático; no se
modifica su selección. La síntesis añade evidencia local reconstruible desde
las cinco restricciones de longitud ya documentadas, no otra física:

`J_i = [Lref*u_ix, Lref*u_iy, cross(B_i-WC,u_i)] / L_i0`,
con u_i dirección unitario inboard→outboard actual y
`Lref=max(L_i0)` de los cinco links. Columnas de traslación escaladas por Lref;
las otras tres son rotaciones infinitesimales sobre ejes globales alrededor WC.
La identidad `u·(domega × r)=domega·(r × u)` da esas derivadas.

Se guardan rcond(J), sign(det(J)), valores estáticos y flags por sample/edge.
Referencia y sample deben superar `sqrt(eps(double))` y conservar orientación
local. Umbral exclusivamente numérico, no constante de ingeniería ni límite
experimental. Fallo/convergencia parcial, conditioning bajo o cambio de
orientación impiden elegibilidad; nunca se interpola para repararlos. El
assessment v0.11 se conserva íntegro pero su PASS no suprime este guard.

**Limitación explícita:** signo de Jacobiano es un guard conservador local,
no una identidad topológica global única ni prueba de que no hay dos raíces
con igual signo. Tampoco verifica todos los pasos internos no publicados.
La continuidad global certificada sigue OPEN DECISION; ningún resultado
se describe como raíz global inequívoca. Se preserva toda pose nativa para
auditar la rama seleccionada y no se asume equivalencia por score.

## Viabilidad y objetivo

Geometry validity, solverStatus/quality, hardFeasibility y target assessment
son campos distintos. Clasificación: INVALID_GEOMETRY; HARD_CONSTRAINT_FAILED
si hay violación demostrada (incluso parcial); SOLVER_FAILED sin muestras
convergidas; INDETERMINATE con calidad/HARD incompletos; NOT_EVALUABLE con otros
requisitos incompletos; SAMPLED_FEASIBLE sólo con todos los requisitos evaluados,
HARD sin violaciones y guard fiable. Sin HARD no implica factibilidad universal.
Una spec sin targets puede evaluar sólo geometría/restricciones nominales;
solver NOT_REQUIRED, sin resultados cinemáticos fabricados.

Entre elegibles se usa **únicamente** compositeScore v0.11 opt-in con todos
los pesos/escalas SOFT explícitos y cobertura completa. No se suman unidades,
no se inventan pesos ni se usan HARD como penalización. Sin score finito se
retienen candidatos y readiness, selectedIndex=NaN. El score es incumplimiento
normalizado: dentro de las bandas puede haber empates aun con residuales distintos.

No hay heurística de penalización de inviabilidad. Desde un incumbent no
elegible se acepta el primer vecino elegible, pero no se rankean intentos
inviables ni se camina entre ellos. **Puede no alcanzar una región factible
lejana**: usar seeds explícitos adecuados. Sin candidatos elegibles se publica
NO_FULLY_EVALUATED_SAMPLED_FEASIBLE_CANDIDATE, nunca una solución ficticia.

## Algoritmo, controles, parada y caché

Polling local determinista en u: seed original primero, luego filas de seeds
del usuario en orden; ejes según orden de parámetros, dirección negativa antes
de positiva. Se exploran todos los vecinos del origen de la iteración; se
actualiza incumbent sólo por nueva elegibilidad o mejora SOFT estricta mayor
que scoreImprovement. Empates mantienen orden previo. Sin mejora, paso *=
stepReduction. Se conservan todos los intentos/candidatos, no sólo aceptados.

Defaults **de software**, no de vehículo: maxEvaluations=40, maxIterations=40,
initialStep=.25, minimumStep=1/1024, stepReduction=.5, scoreImprovement=0,
seeds vacíos, stopAtScore=[] (desactivado). Seeds son matriz S×D en [0,1],
ejes frozen cero. No RNG. Presupuesto global de evaluaciones únicas e iteraciones;
no se reinicia por seed. Stops MAX_EVALUATIONS, MAX_ITERATIONS, MINIMUM_STEP,
NO_FREE_VARIABLES, SCORE_TARGET_REACHED; SEEDS_COMPLETED reservado para término
sin polling. Score target sólo detiene con candidato elegible y score válido.
Reproducibilidad de orden/aceptación/selección exacta en fixture y tolerancia
nativa física; tiempos wall clock nunca son criterio ni identidad.

Caché por vector SI **exactamente** decodificado. Para un espacio fijo cada
vector modifica celdas distintas del mismo seed, de modo que igualdad de clave
equivale a igualdad canónica de geometría; no hay otras fuentes/options variables.
No reutiliza resultados entre espacios/specs/plans. Incluso vectors u distintos
que redondeen a mismo XYZ comparten evidencia sin otro solve. Attempts registran
cacheHit y evaluationId. Los fallos geométricos también tienen clave/registro;
cuentan contra el presupuesto, pero solverCalls=0. physicalBumpSweeps se
publica separado del número de evaluaciones/attempts.

Almacenamiento O(E×N) por estados físicos, más O(A×D) por intentos; caché
exacta lineal y replay/validators conscientes del tamaño. Poll O(D) vecinos
por iteración; no se optimiza prematuramente la integridad. Los presupuestos
acotan E/iteraciones y número de seeds explícito. No garantía de óptimo global,
ni Pareto, ni unicidad, ni exploración exhaustiva del box.

## Resultados, validadores, comparación y gráficos

SynthesisResult guarda problem completo (seed/spec/variables/bounds/plan),
opciones canónicas, registros físicos únicos, claves, historia de todos los
attempts, índices elegibles/selección, stop, diagnóstico y estadísticas.
Cada record: evaluationId, u/x_m, cambios completos, geometry/identity,
candidate con fuentes nativas, assessment, quality/solverStatus/HARD,
classification, eligibility/score, rechazo/excepción y tiempos por capa.
Cada history row: attemptId, evaluationId (referencia sin pérdida al record),
u/clave, iteración, seed de origen, paso, cacheHit, accepted y criterio/reason.
Selected significa mejor score **entre explorados elegibles**, no óptimo global.
Todos los candidatos permanecen, incluidos tradeoffs/empates e intentos fallidos.

Validators reconstruyen espacio, vector/builder, cambios/fixed/identity, fuentes
canónicas/plan y assessment v0.11, guard y clasificación; luego replay del
controlador usando evidencia validada sin solves para verificar history/cache,
opciones, stop/selección/counters. Tiempos deben ser finitos/no negativos y
agregados coherentes; no se demuestra el wall-clock histórico ni autenticidad
criptográfica frente a edición coordinada de todos los inputs.

Comparison usa compareDesignCandidates con misma spec y añade cambios HP y
clasificaciones de síntesis. Plot: scores elegibles (NaN sin score, sin conectar
fallos), u, candidatos elegibles/rechazados acumulados y paso por attempt;
target/curvas/bandas/cobertura/gaps delegados a v0.11. Tema oscuro local antes
de crear hijos, claro explícito disponible; sin preferencias globales nuevas.
No hay solves ocultos en reporting. MAT guarda structs completos; validar al load.

## Correcciones de auditoría V12-F-01/F-02/F-03

### Provenance de ejecución BUMP

`result.execution` y `evaluation.execution` son snapshots generados **antes**
de ejecutar el pipeline, no inferidos del problema al cargar un resultado.
Contienen seedIdentity, specificationIdentity, sourceIds, travel_m y las seis
opciones canónicas de `fsd.kinematics.solverSettings`: MaxContinuationStep_m,
FunctionTolerance, StepTolerance, OptimalityTolerance, MaxIterations y
MaxFunctionEvaluations. Se utilizan esas mismas opciones en la llamada BUMP.
Los defaults y el floor de los dos presupuestos proceden del solver histórico;
las opciones desconocidas se rechazan. Una entrada parcial o MaxIterations=200.9
equivale a los defaults si la fábrica la normaliza a 200. No se redefine el
contrato de normalización del solver ni su algoritmo fsolve fijo.
Las opciones del controlador permanecen en search.options y no son opciones BUMP.

Al invocar BUMP se crea `evaluation.bumpEvidence`, con execution, evaluationId,
geometryIdentity y sweep. Si la llamada no devuelve sweep, éste queda vacío.
Si lo devuelve, se conserva íntegro incluso si el análisis posterior falla.
Las fuentes del candidato deben contener exactamente ese sweep; sus aliases
comparten la misma evidencia. El validador compara snapshot↔problema↔record↔
evidencia↔geometría↔fuentes↔assessment y reconstruye el controlador/historial.
Cambiar sólo problem, o también los snapshots superficiales sin cambiar la
evidencia ligada, no acredita nuevas opciones. Comparación y plot pasan primero
por esta validación global. No se llama BUMP/fsolve para verificar provenance.

Es un contrato de integridad reproducible, **no autenticidad criptográfica**:
no prueba una ejecución histórica ante falsificación coherente de todos los
inputs, evidencias y snapshots. Los MAT previos a estas correcciones sin snapshot
se rechazan; deben regenerarse, no completar provenance retrospectivamente.
El schema de milestone continúa 0.12.0; no cambian los payloads históricos.

### Política cerrada de fallos recuperables

| Etapa | Identificadores recuperables exactos |
|---|---|
| BUILDER | fsd:model:CoincidentUcaPivots, fsd:model:CoincidentLcaPivots, fsd:model:ZeroLengthUcaLink, fsd:model:ZeroLengthLcaLink, fsd:synthesis:DegenerateWishbone |
| BUMP | fsd:kinematics:InvalidWheelAxisOrientation |
| ANALYSIS | fsd:analysis:DegenerateCasterProjection, fsd:analysis:DegenerateKingpinProjection, fsd:analysis:DegenerateToeProjection, fsd:analysis:InvalidWheelAxisOrientation |

No se recupera por prefijo, mensaje o cualquier catch. Errores desconocidos,
tipos/fields/invariantes, opciones inválidas y dependencias ausentes se relanzan.
La no convergencia ordinaria ya es un resultado nativo PARTIAL_OR_FAILED;
no se inventa otro identificador de excepción ni un solver nuevo.
Dos handles opcionales **privados** de evaluateCore permiten fault injection
en tests de frontera, sin ofrecer un adapter público ni modificar solvers.

El record conserva ID/u/x, snapshot, geometry/identity/changes cuando el builder
terminó, `failureStage`, exceptionId/message y `evidenceStatus`:
NO_GEOMETRY, GEOMETRY_ONLY, BUMP_AVAILABLE o ASSESSED. Un rechazo del builder
no publica una geometría como aceptada; su vector y seed permiten reconstruir
el intento. Fallos BUMP se clasifican SOLVER_FAILED; fallos posteriores,
ANALYSIS_FAILED. Ambos tienen candidate/assessment vacíos, HARD NOT_EVALUATED,
eligible=false y score=NaN. Un BUMP convergido no hace válido el análisis.
La política no añade puntuación de penalización ni permite caminar entre fallos.

Una evaluación única fallida consume presupuesto y tiene history por ID; la
caché conserva también ese record sin otro solve. solverCalls cuenta **invocaciones
de sweep**, incluyendo las que lanzan excepción, no pasos internos de fsolve.
Una excepción BUILDER cuenta 0; BUMP/ANALYSIS cuenta 1. El nombre histórico
statistics.physicalBumpSweeps conserva esta semántica de invocaciones.
Tiempos de etapas posteriores no intentadas quedan 0, no magnitudes físicas.

El validador reconstruye el fallo BUILDER y, para ANALYSIS, valida el sweep y
repite únicamente el análisis algebraico para exigir el mismo ID/mensaje.
Para una excepción BUMP sin sweep no puede reconstruir un estado que no existe:
exige contrato/opciones/etapa/ID permitido/diagnóstico no vacío, ausencia de
fuentes y conteos coherentes, sin fingir certificar el hecho histórico. Rechaza
scores, elegibilidad, assessments, estados, calidad o selección contradictorios.

V12-F-04 incorpora exclusivamente ZeroLengthUcaLink y ZeroLengthLcaLink a BUILDER:
son errores del validador geométrico existente al coincidir un pivote UCA/LCA
con UBJ/LBJ, no nuevas ecuaciones ni tolerancias. El intento conserva ID/u/x_m,
snapshot, etapa/ID/mensaje nativo; geometry/geometryIdentity/candidate/assessment/
bumpEvidence quedan vacíos, geometryValid=false, eligible=false y score=NaN.
La propuesta XYZ se reconstruye desde seed, variables y x_m: no se publica como
geometría construida ni se inventa su identidad. Consume una evaluación única,
puede producir cache hits, pero solverCalls=0. El controlador continúa cuando
quedan propuestas y presupuesto; validadores reconstruyen el rechazo sin BUMP.
Errores desconocidos siguen relanzándose. No cambia HARD/SOFT ni la selección.

### Reporting con cero, uno o varios candidatos disponibles

El trace siempre conserva todos los records/scores NaN/gaps y attempts. Con un
candidato se llama directamente al plot de targets v0.11; sólo dos o más invocan
comparación. `compareSynthesisCandidates` mantiene su requisito de dos candidatos.
Sin candidato se dibujan trace y diagnósticos, no curvas ni solución inventada.
Si no hay elegibles o hay menos de dos candidatos representables se añade una
figura de estados de todos los intentos y detalle del seleccionado, o del primer
intento cuando selectedIndex es NaN; se identifica seed=1 y NO_AUTOMATIC_WINNER.
Muestra score disponible, etapa/error/evidencia y cambios HP con unidades m.
UserData de trace/diagnósticos conserva todos los records completos; no reemplaza
el resultado serializable. Candidatos rechazados representables se etiquetan
con su clasificación, nunca se seleccionan silenciosamente.
Nudos/bandas/muestras/cobertura/HARD-SOFT y gaps siguen siendo los nativos.
Texto de diagnóstico gris sRGB .46 contrasta con oscuro y claro; es una decisión
de presentación, no ingeniería. El tema es local y se establece antes de hijos.
Presupuesto mínimo 1: un resultado sin ninguna evaluación sigue siendo inválido.

Regresiones, PNGs de primera sesión, benchmark y límites de evidencia:
[informe de correcciones](v0.12-audit-corrections.md).

## Dependencias y limitaciones abiertas

Búsqueda genérica: base MATLAB, sin Optimization/Global Optimization Toolbox.
Pipeline físico: **mantiene dependencia histórica Optimization Toolbox/fsolve**.
No se oculta ni se sustituye el solver para prometer independencia no existente.
Sin fsolve el coordinador rechaza antes de la búsqueda física.

OPEN DECISION: targets/escalas/pesos/tolerancias reales; validación experimental,
certificación de ramas/recorrido continuo, tolerancias de fabricación y
reconstrucción de nuevos adapters. Se preservan para futuras milestones:
generación inicial desde concepto, múltiples corners/ejes, inverse steering/
actuation/rocker, multiobjetivo/Pareto, performance y targets razonados,
packaging/colisiones, rules versionadas, anti geometry, ARB con las tres
estrategias, Tilt Test, robustez y Adams. Seed es una limitación temporal,
no el objetivo final del producto. No v0.13, CAD general, UI ni nueva tecnología.
