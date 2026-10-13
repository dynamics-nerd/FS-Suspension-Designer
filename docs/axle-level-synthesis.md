# v0.13 — Axle-Level Suspension Synthesis

MATLAB R2025b, structs/MAT, core headless. Un eje es FRONT (FL/FR) o REAR
(RL/RR), orden izquierda/derecha obligatorio. Dos seeds explícitos válidos;
no se genera una esquina ausente. Se conserva +X atrás, +Y derecha, +Z arriba
y SI (m/rad). No cambia física, tolerancias ni contratos v0.1–v0.12.

## APIs

```matlab
space = fsd.synthesis.createAxleDesignSpace(leftSeed,rightSeed,spec,plan,links);
fsd.synthesis.validateAxleDesignSpace(space);
u = fsd.synthesis.normalizeAxleVariables(space,space.initial_m);
x_m = fsd.synthesis.denormalizeAxleVariables(space,u);
[axle,changes] = fsd.synthesis.buildAxleCandidate(space,x_m);
evaluation = fsd.synthesis.evaluateAxleCandidate(space,u,1);
result = fsd.synthesis.runAxleInverseSearch(space,options);
fsd.synthesis.validateAxleSynthesisEvaluation(evaluation,space);
fsd.synthesis.validateAxleSynthesisResult(result);
comparison = fsd.synthesis.compareAxleSynthesisCandidates(result,[1;2]);
figures = fsd.synthesis.plotAxleSynthesisResult(result);
save('output/my-axle.mat','result');
```

Build recibe coordenadas **independientes en metros**, evaluate recibe u.
Comparación exige dos índices distintos con candidato disponible. Plot acepta
uno o cero índices y nunca sustituye un fallo por una solución. Tras load,
validar el resultado íntegro antes de utilizarlo.

## Problema físico y planes

Los dos seeds deben compartir referenceFrame completo (también descripción de
origen), schema, eje y convención. El caller es responsable de que ese frame
describa realmente la misma referencia del vehículo; el texto no es una medida.
No se necesita masa/CG/wheelbase para BUMP ni para el body-roll reducido v0.6.
No se introduce un VehicleParameters ficticio.

```matlab
plan.leftBump  = struct('travel_m',[-.01;0;.01],'solverOptions',struct());
plan.rightBump = struct('travel_m',[-.01;0;.01],'solverOptions',struct());
plan.roll = struct('angles_rad',[-.01;0;.01], ...
    'axleHeave_m',0,'solverOptions',struct());  % opcional, elección del usuario
links = ["FL_UPPER_Z_1","FR_UPPER_Z_1"];       % opcional: IDs de parámetros
```

Son ejemplos de contrato, **no recorridos FS recomendados**. Cada grid es
finito, estrictamente monótono o escalar, conservando orden; no se amplía para
cubrir targets. BUMP permite opciones diferentes por lado. ROLL exige su
ángulo y heave medio explícitos: h=(zLeft+zRight)/2, no altura de chasis ni ride
height. Su CornerSolverOptions compartido es exactamente el contrato nativo,
separado de las dos opciones BUMP. Defaults y normalización proceden de
solverSettings/rollSolverSettings, sin nuevos presets físicos.

Si roll no existe o está vacío, no se ejecuta. Un target ROLL sin plan se
rechaza con MissingAnalysisPlan; un heave del target distinto del plan se
rechaza, no se descarta ni corrige. El datum de cada rueda debe satisfacer
la precondición nativa de círculo rígido inferior y suelo nominal Z=0. Esta
precondición se verifica algebraicamente antes del search.

## Variables, FIXED y simetría

Se consumen todos los FREE/RANGE v0.11 con bounds finitos y bindings HARDPOINT_X/Y/Z
de los cuatro UCA/LCA FWD/AFT_CHASSIS de cada corner: hasta 24 coordenadas.
IDs de parámetros, points y fuentes no se cruzan. KNOWN no significa FIXED;
los parámetros conceptuales desconocidos siguen registrados sin rellenarlos.
No se controlan outboards, tie rods, rack, wheel axis, actuation o muelles.

Cada cornerSpace reutiliza spaceCore v0.12 para autorización/FIXED/provenance.
La spec original completa, no la suma de dos assessments, evalúa el candidato.
FIXED y HARDPOINT_FIXED HARD se comprueban en seeds y prohíben una variable
móvil aun con tolerancia no cero. AXIS_ALIGNED_BOX se evalúa sobre los dos
modelos nominales reconstruidos, sin clipping de geometría ni promesa de CAD.

Links es un array string N×2 [leftParameterId,rightParameterId]. Vacío implica
diseño independiente, sin exigir geometrías simétricas. Un link admite sólo
el mismo rol de hardpoint y componente: xR=xL, zR=zL, yR=-yL sobre Y=0.
Los seeds deben satisfacer exactamente la relación seleccionada; no se ajustan
con una tolerancia oculta. Los wheel axes deben ser reflejos outward coherentes
y se mantienen inmutables. No se refleja ninguna curva de respuesta.

La variable derecha enlazada deja de ser un DOF independiente. Se intersectan
los bounds izquierdos con los derechos transformados; un partner congelado
congela el DOF. Una incompatibilidad, ID duplicado, vínculo repetido/invertido,
rol distinto o FIXED móvil se rechaza. physicalVariables preserva ambas
declaraciones, independentIndex/multiplier describen el mapa, variables contiene
únicamente los DOFs independientes. Orden: parámetros de la izquierda, después
derecha no dependiente; dentro de cada lado, orden de la especificación.

**Simetría seleccionada, no simetría completa:** sólo las coordenadas vinculadas
obedecen el espejo. No se afirma que outboards u otras coordenadas asimétricas
sean reflejos. El plano del proyecto sigue Y=0; no hay planos desplazados,
offsets ni un motor de relaciones arbitrarias. Seeds faltantes nunca se infieren.

## Builder e identidades

El mapa físico precede a buildCore v0.12 en ambos lados. La fábrica/validators
canónicos y el guard histórico de triángulos rechazan pivotes coincidentes,
links nulos o brazos collineales antes de cualquier solver. Sólo se cambian las
celdas autorizadas; wheel axis, outboards, frame y metadata se conservan.
Cambios DERIVED enlazan el parámetro/provenance, no se etiquetan como medidos.
No hay campos de link length estáticos obsoletos.

Se usa AxleGeometry/axleIdentity histórico, con las dos geometryIdentity
completas. Cambiar cualquiera cambia la identidad conjunta. El builder es
atómico: si falla un lado, no publica un eje válido ni identidades parciales;
u/x, seed, bindings y diagnóstico permiten reconstruir la propuesta rechazada.
Structs por valor preservan seeds y otros candidatos; MAT guarda todos juntos.
La aceptación del seed al definir el espacio significa validez del contrato
DoubleWishboneGeometry nativo. El guard adicional de triángulos v0.12 se aplica
en el builder también al primer intento: un seed admitido por ese schema pero
collinear se conserva como INVALID_GEOMETRY, nunca pasa al solver ni se publica
como candidato válido. Esta frontera conserva la política histórica de fallos.

## Fuentes nativas y alcance

Todo eje geométricamente válido invoca BUMP izquierdo y derecho, incluso si
no hay targets BUMP o uno de los análisis falla. Cada fuente conserva modelo,
sweep completo, análisis, grid, opciones efectivas, convergencia/gaps y guard
local v0.12. Aliases dentro del mismo lado comparten exactamente esa evidencia;
un source ID no puede representar ambos lados ni mezclar familias.

| Fuente | Métricas reconstruidas |
|---|---|
| BUMP por corner | CAMBER, TOE, BUMP_STEER, CASTER, KPI |
| ROLL por corner | CAMBER (chassis), ROAD_CAMBER, TOE |
| ROLL por eje | ROLL_CENTER_HEIGHT, ROLL_CENTER_ROAD_HEIGHT, ROLL_CENTER_Y, WHEEL_CENTER_TRACK_CHANGE |

ROLL ejecuta solveAxleRollSweep sobre **ambas geometrías nuevas**, después
analyzeAxleRollSweep y los adaptadores originales v0.11. No es 2×BUMP ni una
nueva fórmula de RC. Altura histórica del RC puede estar indisponible si los
contactos no comparten Z; road height es otra métrica. Rcond/orientation de
v0.12 se reconstruyen por corner en cada pose ROLL aceptada; además se conservan
las verificaciones nativas de carretera/roll center/conditioning del adaptador.
No se certifican pasos internos no publicados ni unicidad global de rama.

RACK/Ackermann/actuation/mechanical/static loads/global static y source identity
bloqueada se rechazan antes de buscar con ID y reconstrucción faltante. Un
target soportado sin cobertura/calidad suficiente permanece NOT_EVALUATED o
PARTIALLY_EVALUATED en el assessment, distinto de unsupported. No se ignoran
requisitos ni se fabrican métricas para plots.

## HARD/SOFT, errores y selección

Un único DesignCandidate contiene ambas geometrías y las fuentes disponibles;
un único evaluateDesignCandidate aplica la spec conjunta y los pesos/escalas
explícitos. Los resultados válidos de un lado se conservan si el otro no puede
analizarse; su ausencia no se transforma en PASS. No se suman dos scores ni se
introduce penalización finita de inviabilidad.

geometryValid, analysisStatus (tres entradas), hardFeasibility y softScoreStatus
son independientes. Clasificación conservadora por prioridad:
INVALID_GEOMETRY; HARD_CONSTRAINT_FAILED demostrado; LEFT_NOT_EVALUABLE;
RIGHT_NOT_EVALUABLE; JOINT_ANALYSIS_UNAVAILABLE; INDETERMINATE HARD;
NOT_EVALUABLE por otros requisitos incompletos; SAMPLED_FEASIBLE sólo con
calidad de todos los planes y requisitos completamente evaluados.
Cada lado conserva sus motivos, aunque la clasificación primaria sea una sola.
SOFT puede incumplirse con elegibilidad, pero cobertura incompleta no la concede.

La allowlist cerrada BUILDER/BUMP/ANALYSIS v0.12 se reutiliza sin ampliarla;
un fallo de solver nativo ROLL usa la misma frontera física de esquina BUMP.
No convergencia de ROLL se conserva como payload nativo, no excepción inventada.
Errores desconocidos/invariantes/toolbox se relanzan. En fallo ANALYSIS se
conservan sweep/calidad, sin análisis falso. Un fallo SOLVER sin sweep no aporta
estado certificable; sólo contrato de invocación/diagnóstico permitido.

Elegibles usan únicamente compositeScore v0.11. NaN sin score explícito completo;
ningún ganador automático. Selected es el mejor score entre explorados elegibles,
no óptimo global ni cumplimiento continuo. Score cero significa violación
normalizada muestreada nula dentro de las bandas del usuario.

## Search, budgets, caché y provenance

Se llama al boundedDirectSearch existente, sin otro optimizador/refactor: mismo
orden/poll/seeds/pasos/stops/budgets/elegibilidad y limitación de no caminar entre
inviables. Seeds del controller son vectors u del **mismo problema de dos seeds
geométricos**, no se sustituyen modelos silenciosamente.

La clave es el vector SI independiente exacto dentro de un problema inmutable;
su mapa determinista determina ambas geometrías. No hay caché persistente entre
problemas. Cambiar geometría/plan/opciones/spec/vínculos exige otro contexto.
Invalid attempts también consumen presupuesto y se reutilizan sin solve.

Statistics distingue axleCandidateEvaluations/attempts/cacheHits,
leftBumpSweeps/rightBumpSweeps/rollSweeps, totalPhysicalSweepInvocations,
preSolverFailures y nativeRollCornerSolves. Una invocación de sweep no equivale
a una iteración fsolve: ROLL contiene muchos cierres de esquina. No se presenta
E7 como siete solves físicos: en el benchmark son 21 invocaciones de sweep.
Native diagnostics retienen iteraciones/evaluaciones internas completas.
Estos contadores pertenecen exclusivamente a la búsqueda. El ejemplo ejecuta
además tres sweeps para la referencia y tres para la repetición independiente
del seleccionado: seis invocaciones fuera de result.statistics, no ocultas
en validators ni assessment. El ejemplo completo suma27 sweeps en su modo
simétrico; el search,21.

Snapshot al ejecutar incluye ambas seed identities, frame común, spec,
variables/mapping/links, grids y opciones canónicas de todos los planes/source IDs.
Cada wrapper físico liga snapshot, evaluationId, modelIdentity y sweep. Result,
record, wrapper, candidate, assessment e history deben ser coherentes.
Cambiar snapshots superficiales sin cambiar evidencia ligada no acredita otro
plan. No hay firma/autenticidad ante falsificación coordinada total de inputs.

## Validación, reporting y límites

Validators reconstruyen espacio/mapa/builders/rechazos/evidencia nativa/calidad/
assessment y replay exacto del controller. Repetir análisis algebraico no ejecuta
solvers. Comprueban score/selección/history/cache/contadores y tiempos no negativos
coherentes, sin demostrar el wall-clock histórico. MAT incompleto o manipulado
se rechaza; no se rellena provenance retrospectiva.

Plot devuelve trace (score NaN/u/counts/pasos), diagnósticos de todos los records,
plots originales de targets/bandas/knots/gaps/cobertura de ambos lados/ROLL,
y geometrías por evaluación válida. Por defecto seed y selected si existe;
no hay sustituto del ganador ausente. UserData conserva records y planes.
Tema oscuro local antes de hijos, claro explícito; layout suficientemente amplio
para primera exportación. Sin callbacks/UI ni nuevos solves en reporting.

Engineering change → Unit test → Known case → Validation → Merge; merge queda
fuera de esta tarea. BUMP/ROLL requieren Optimization Toolbox; controller usa
base MATLAB. Ejemplo y benchmark en axleSuspensionSynthesisExample y
[evidencia](v0.13-validation.md).

OPEN DECISION: targets/pesos/escalas/tolerancias/medidas reales, validación
experimental, ramas/continuidad certificadas, simetría completa o planos
desplazados, nuevos adapters de dirección/actuación/equilibrio y robustez.
No fabricación, CAD, compliance, normativa, dinámica, UI, Adams, NSGA/Pareto
ni v0.14. Los seeds son una limitación temporal, no un generador desde concepto.
