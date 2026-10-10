# v0.11 — Design Requirements, Targets & Evaluation

Esta capa permite expresar conocimiento, decisiones, límites y objetivos, y
evaluar resultados **ya calculados**. No genera geometrías ni targets óptimos,
no modifica modelos y no contiene un optimizador. MATLAB R2025b, structs/MAT,
mismas convenciones físicas que v0.10: **+X atrás, +Y derecha, +Z arriba**.

## Separación de responsabilidades

`fsd.model` define DesignParameter, DesignTarget, SuspensionDesignTargets,
DesignConstraint, DesignSpecification y DesignCandidate. No llama a analysis
ni a solvers. `fsd.analysis` valida las fuentes originales, adapta sus métricas
y produce DesignAssessment/DesignComparison, tablas y gráficos. Los solvers
anteriores no conocen la especificación. No se añade otra capa de paquetes.

El flujo es: datos/hipótesis → especificación independiente → generación
**explícita externa** de resultados nativos → candidato → validación upstream
una vez por fuente y llamada → comparación privada → evaluación/reporting.
Reconstruir análisis para verificar integridad no significa volver a resolver
un mecanismo. Los validadores nativos conservan sus verificaciones de cierre,
identidad y calidad; el evaluador no llama a solves ni selecciona otras raíces.

## Parámetros y conocimiento progresivo

Cada registro tiene `schemaVersion`, `kind`, `definitionSI`, `identity` y
`metadata`. ID estable mayúsculo `^[A-Z][A-Z0-9_]*$`; display name y prioridad
de evento en metadata, nunca usados como IDs ni pesos implícitos. Los IDs de
requisitos deben ser únicos en toda la especificación.

La definición del parámetro contiene `id`, `quantity`, `unit`, `scope`, `type`,
`value`, `bounds`, `binding`, `comparisonTolerance`, `availability`, `sourceKind`,
`sourceNote`, `ruleReference`, `derivationReference` y `description`.

| Rol (vocabulario compatible con v0.9) | Semántica |
|---|---|
| KNOWN | Dato suministrado; NO se convierte en restricción FIXED |
| FIXED | Decisión impuesta; con binding exige valor y tolerancia explícita |
| RANGE | Intervalo cerrado explícito; no implica nominal |
| FREE | Modificable, con límites o límites pendientes; no implica optimizador |
| TARGET | Intención conceptual; la aceptación numérica reside en DesignTarget |
| DERIVED | Dato calculado; exige provenance DERIVED y referencia de cálculo |
| ASSUMED | Hipótesis explícita; no puede publicarse como medida KNOWN |
| RULE | Referencia normativa estructurada; no ejecuta una regla |

Rol de diseño y procedencia no son lo mismo: `sourceKind` reutiliza
KNOWN/ASSUMED/DERIVED/UNSPECIFIED del contrato de hardpoints. Disponibilidad:
NOT_PROVIDED, NOT_APPLICABLE, KNOWN, ASSUMED, DERIVED, PENDING_CALCULATION o
INVALID. Sólo KNOWN/ASSUMED/DERIVED admiten un valor finito, con nota y
procedencia coincidentes. Ausente se guarda `[]`, jamás cero. RANGE puede
tener bounds sin valor. DERIVED documenta una referencia, **no verifica una
derivación física arbitraria ni añade un motor de expresiones**.

RULE exige organizador, versión/año, ruleId, quantity, fuente, status y
aplicabilidad. Una referencia UNVERIFIED sigue sin demostrar normativa; no
hay límites Formula Student incorporados ni un Rules Engine.

## Scopes, unidades y bindings

`designScope(kind,id,cornerId)` admite VEHICLE/VEHICLE, AXLE/FRONT o REAR,
CORNER/FL/FR/RL/RR, COMPONENT/id+corner y HARDPOINT/id canónico+corner.
No se exige un vehículo de cuatro esquinas para una especificación inicial.

`convertDesignUnits` y las fábricas convierten únicamente en la frontera:
longitud m/mm→m, ángulo rad/deg→rad, fuerza N, rigidez N/m o N/mm→N/m,
damping N*s/m o N/(mm/s)→N*s/m, masa kg, tiempo s, ratios 1 y fracciones
1/%→1. La magnitud se declara, no se deduce de la unidad; un porcentaje
no sustituye un ratio firmado. Bounds, nominal, tolerancias y escalas reciben
la misma conversión. `conditions.wheelTravel_m` y `axleHeave_m` ya son SI por
contrato y no se convierten según la unidad de la coordenada del target.

Bindings implementados: HARDPOINT_X/Y/Z; SPRING_RATE/SPRING_PRELOAD del source
MECHANICAL identificado por el componente y su corner; VEHICLE_WHEELBASE,
FRONT_TRACK, REAR_TRACK y MASS de `candidate.vehicle`. Binding NONE permite
documentar otros parámetros, pero **no los presenta como variables evaluables**.
No hay acceso a campos físicos mediante strings arbitrarios.

FIXED con binding se compara con tolerancia explícita >=0. RANGE/FREE con
binding y bounds son restricciones HARD sobre el valor nominal del modelo;
sin bounds son NOT_EVALUATED. `designVariableSpace(spec,true)` rechaza falta
de bounds finitos o binding; `false` conserva un espacio incompleto. Esta
API no garantiza factibilidad física ni propone valores ni ejecuta búsquedas.

## Restricciones geométricas

DesignConstraint admite HARDPOINT_FIXED (`position` XYZ y tolerancia escalar
por coordenada) y AXIS_ALIGNED_BOX (`bounds` 3×2, columnas mínimo/máximo).
Coordenadas m en VEHICLE_GLOBAL; box cerrado, frontera incluida. Scope
HARDPOINT identifica un punto **nominal registrado** en el candidato. No
comprueba una envolvente durante el movimiento ni colisiones CAD. Tanto
HARD como SOFT son explícitos; la preferencia SOFT no invalida automáticamente.

## Catálogo real de métricas (23 IDs)

La API `designMetricCatalog` especifica ID, magnitud, unidad, scope,
sourceTypes/independentVariables emparejados, escalar/curva, signo,
prerrequisitos y validez. Un scalar sobre un sweep necesita coordenada exacta.

| ID | Fuente / coordenada | Scope / unidad / referencia |
|---|---|---|
| CAMBER | BUMP/wheel travel; ROLL/roll angle | corner, rad; top inward negativo, chassis frame |
| ROAD_CAMBER | ROLL/roll angle | corner, rad; road frame v0.6 |
| TOE | BUMP, RACK, ROLL / respectivas coordenadas | corner, rad; toe-in positivo |
| BUMP_STEER | BUMP/wheel travel | corner, rad; toe menos staticToe, aunque no haya sample cero |
| CASTER, KPI | BUMP/wheel travel | corner, rad; signos históricos |
| ROAD_WHEEL_ANGLE | RACK/rack travel | corner FL/FR, rad; heading positivo hacia +Y |
| SCRUB_RADIUS, MECHANICAL_TRAIL | RACK/rack travel | corner FL/FR, m; outboard/forward positivos |
| ACKERMANN_ANGLE_ERROR | RACK/rack travel | FRONT, rad; actualOuter−idealOuter wrapped, NO porcentaje |
| ROLL_CENTER_HEIGHT | ROLL/roll angle | axle, m; sobre nivel común de contactos, no válida a cualquier roll |
| ROLL_CENTER_ROAD_HEIGHT | ROLL/roll angle | axle, m; altura perpendicular a road |
| ROLL_CENTER_Y | ROLL/roll angle | axle, m; Y en chassis; permite observar migración, no otro solver |
| WHEEL_CENTER_TRACK_CHANGE | ROLL/roll angle | axle, m; respecto h=0,phi=0 |
| DAMPER_COMPRESSION | ACTUATION o MECHANICAL/wheel travel | corner, m; shortening desde nominal positivo |
| MOTION_RATIO | ACTUATION o MECHANICAL/wheel travel | corner, 1; dc/dz firmado |
| INSTALLATION_RATIO | ACTUATION o MECHANICAL/wheel travel | corner, 1; abs(MR), NO recíproco |
| SPRING_AXIAL_FORCE | MECHANICAL/wheel travel | corner, N; compresión axial no negativa |
| SPRING_WHEEL_RESISTANCE | MECHANICAL/wheel travel | corner, N; Fs*MR firmado, NO normal de neumático |
| TANGENT_WHEEL_RATE | MECHANICAL/wheel travel | corner, N/m; total elástico+geométrico, sin clamping |
| CORNER_LOAD | STATIC_LOADS o GLOBAL_STATIC/NONE | corner, N; normal de contacto |
| CROSSWEIGHT | STATIC_LOADS o GLOBAL_STATIC/NONE | VEHICLE, 1; v0.9 denomina M*g, v0.10 suma de normales |
| REFERENCE_HEIGHT | GLOBAL_STATIC/NONE | VEHICLE, m; subjectId de punto del chasis, world Z |

BUMP exige modelo + sweep + BumpSweepAnalysis; RACK SteeringSystemGeometry +
RackSweepResult + análisis y `conditions.wheelTravel_m=[left,right]` explícito;
ROLL AxleGeometry + sweep + análisis y `conditions.axleHeave_m` explícito.
ACTUATION necesita modelo/sweep/análisis. MECHANICAL modelo/resultado y
auxiliary ActuationGeometry para paths de producción; para prescribed path,
auxiliary vacío y el resultado conserva su origen ideal/ASSUMED. No se fabrica
un ActuationResult para un benchmark 1-D.

RC exige FINITE/no ill conditioning; no sustituye infinito por un número grande.
Ackermann exige VALID y ambos ICR fiables, no una falsa métrica en straight.
MR exige disponibilidad upstream; wheel rate exige su status AVAILABLE,
incluida segunda derivada fiable F-01. Fuera de límites mecánicos declarados
no se da PASS. Un global sin selectedIndex no usa alternatives{1}. Referencias
de altura no definidas no se inventan. STATIC_LOADS sólo publica muestras
finitas con balance conocido; familia indeterminada no es un setup.

No se admite CAMBER desde RACK porque RackSweepAnalysis no lo publica; no
se añade un cálculo para rellenar el catálogo. No se implementan grip, anti,
frecuencias, roll axis ni métricas de rendimiento.

## Targets y contratos de comparación

`createDesignTarget(definition,inputUnit,coordinateUnit)` requiere ID, metricId,
sourceId/sourceType, scope, type, strength, independentVariable y sourceNote.
POINT_TARGET exige nominal y tolerancia; VALUE_BAND ambos límites ordenados;
UPPER_BOUND/LOWER_BOUND un límite; CURVE_TARGET nominal+tolerancia por knot;
CURVE_BAND lower/upper por knot. Constantes se expanden explícitamente sobre
los knots. Curvas columna >=2, estrictamente ascendentes o descendentes,
sin duplicados ni NaN/Inf. Tipos incompletos se rechazan, incluidos HARD.

Las tolerancias target, numericalTolerance y physicalUncertainty son campos
distintos. Los últimos dos son anotaciones explícitas, no relajan aceptación
ni reparan la calidad upstream ni propagan incertidumbre en v0.11.
`transform=ABS` es opcional explícito (p.ej. límite de abs(bumpSteer)); IDENTITY
conserva signos. requiredSourceIdentity opcional liga una fuente exacta;
aun sin él se verifican el sourceId/tipo, identidad nativa, scope, controles y
referencias del resultado suministrado. No hay asignación implícita por orden.

No se copian automáticamente targets entre corners. `mirrorBumpDesignTarget`
es una operación explícita y limitada a BUMP camber/toe/bumpSteer/caster/KPI
sin sourceIdentity fijada: conserva su signo side-independent, cambia corner
y sourceId. **No demuestra que el candidato sea simétrico**. Heading de RACK
no usa esa regla: sus signos globales requieren otra especificación.

## Errores, normalización y score

Para nominal t, resultado y y tolerancia tau: desviación d=y−t;
incumplimiento v=max(abs(d)−tau,0). Banda: d=y−clamp(y,l,u),
v=max(l−y,y−u,0). Upper: d=y−u,v=max(d,0). Lower: d=y−l,v=max(−d,0).
La aceptación usa desigualdad inclusiva, no una epsilon oculta.

`normalizationScale=s>0` exige normalizationNote; residual d/s e
incumplimiento v/s. No se infiere s del target, de tau ni de valores típicos.
Sin escala los normalizados son NaN, no puntuaciones adimensionales inventadas.
Los errores individuales permanecen siempre; máximo absoluto/normalizado y
número de violaciones sólo usan muestras válidas.

Para curva ordenada, E son edges entre muestras válidas adyacentes conectadas,
dx_i=x_(i+1)−x_i. RMS normalizado muestreado:
`sqrt(sum_E(dx_i*(r_i^2+r_(i+1)^2)/2)/sum_E(dx_i))`.
Es cuadratura trapezoidal de residual al cuadrado, **no RMS analítico continuo**.
Malla no uniforme ponderada por dominio, no por recuento; sin edges, RMS NaN.
Para scalar RMS=abs(r). Mismo algoritmo para incumplimiento normalizado.

Score opcional sólo con `compositeScore=true` y escala+weight>0 para **todos**
los SOFT: `sqrt(sum(w_j*RMS(v_j/s_j)^2)/sum(w_j))`. Requiere cobertura completa
muestreada y RMS finito de todos los SOFT; si falta, NaN/UNAVAILABLE_COVERAGE.
HARD no participa, score no implica óptimo, Pareto ni desempeño del vehículo.

## Curvas, gaps y cobertura

Se interpola **el target linealmente**, no los resultados. La malla comparada
son samples reales dentro del dominio más sus extremos solicitados; los
extremos sin sample real quedan no evaluados. Los knots internos del target
no fabrican samples de producción. No se extrapola. El scalar requiere
igualdad exacta de la coordenada solicitada; planificar los sweeps de antemano.
Sweep descendente se invierte coherentemente; no monótono queda no evaluable,
no se ordena arbitrariamente un path con historial de continuación.

No se unen NOT_ATTEMPTED, fallos, estados no fiables ni cambios de índice de
rama del rocker. Esta política de índice es conservadora: puede marcar un
gap adicional al cambiar la enumeración; no declara conectividad física nueva.
Actual conserva el dato fuente; valid/status impiden usarlo como válido.
Errores/plots en muestras inválidas son NaN; no se integra un edge inválido.

Cada target informa requestedDomain, availableIntervals, evaluated y unavailable
sample counts, sampleCoverage, domainCoverage, evaluatedDomainLength, reasons,
valid, connected, agregados y aggregatesPartial. Cobertura de dominio es
longitud de edges válidos / longitud solicitada. No equivale a certificación
continua. `verificationDomain=SAMPLES_ONLY`:

- SAMPLED_PASS: muestras disponibles/conectadas y ninguna violación.
- SAMPLED_FAIL: cobertura muestreada completa con alguna violación.
- PARTIALLY_EVALUATED: alguna muestra válida pero falta cobertura/conectividad.
- NOT_EVALUATED: ninguna muestra válida.

Un HARD con violación demostrada es INFEASIBLE_FOR_SPECIFICATION incluso si
parcial. Falta de HARD sin violación conocida: INDETERMINATE_HARD_REQUIREMENTS;
todos evaluados y satisfechos: SATISFIES_SAMPLED_HARD_REQUIREMENTS. Sin HARD:
NO_HARD_REQUIREMENTS, **no** afirmación de factibilidad física universal.
SOFT fallido no convierte automáticamente en inviabilidad.

## Candidatos, identidad e integridad

DesignCandidate guarda ID, geometrías nominales opcionales, vehículo opcional,
sources y metadata. Source explícito `{id,type,model,result,sweep,auxiliary}`;
su tipo selecciona un adaptador cerrado, no rutas de campos arbitrarias.
Candidate.identity sólo guarda identidades y controles necesarios (paths/poses
compactos); no copia análisis voluminosos. Assessment liga spec y candidato
por identidad y sólo guarda valores comparados, no otro agregado completo.

Las identidades canónicas son structs transparentes, no hashes criptográficos.
Cambian con parámetros/scopes/targets/tolerancias/escala/opciones/hipótesis;
metadata de presentación no las cambia. Se comprueban modelos originales,
relaciones geometric/mechanical/vehicle y payloads upstream completos.
`fsd.model.validateDesignCandidate` es estructural, respetando el DAG;
**`fsd.analysis.validateDesignCandidate`** verifica también las fuentes.
`validateDesignAssessment(assessment,spec,candidate)` reconstruye todo el
assessment desde fuentes originales y rechaza incoherencia de valores,
orden, cobertura, errores, RMS, estados, HARD/SOFT, identidades y score.
Esto no proporciona firma/autenticidad ante edición coordinada de todos los
inputs externos; tampoco prueba que una hipótesis sea verdadera.

## Readiness, comparación y visualización

Readiness registra unknownParameters, variables sin límites/bindings,
status/prerrequisitos/source/scope/condiciones/referencia de cada target y
motivos de falta/calidad. allRequirementsEvaluated significa que se pudieron
comparar, **no** que se cumplan ni que los datos desconocidos estén completos.
Prioridades SKIDPAD/ACCELERATION/AUTOCROSS/ENDURANCE/BALANCED pueden guardarse
como metadata, sin pesos automáticos ni predicción de grip/lap time.

`compareDesignCandidates(spec,{a;b;...})` usa una sola especificación y IDs
distintos, conserva assessments/errores/HARD y NO_AUTOMATIC_WINNER. Steering
ausente no impide evaluar camber. `designAssessmentTable` valida íntegramente
y muestra requisito/métrica/scope/strength/status/error/unidad/cobertura/missing.
`plotDesignTargetEvaluation` dibuja target, límites, candidatos identificados,
desviaciones, cruces rojas de violación y separadores NaN en gaps; no une fallos.

## Uso mínimo y edición

```matlab
scope = fsd.model.designScope("CORNER","FL");
t = fsd.model.createDesignTarget(struct("id","CAMBER_FL","metricId","CAMBER", ...
    "sourceId","BUMP_FL","sourceType","BUMP","scope",scope, ...
    "type","CURVE_TARGET","strength","SOFT","independentVariable","WHEEL_TRAVEL", ...
    "x",[-20;20],"value",-1,"tolerance",.1,"sourceNote","Illustrative user target"),"deg","mm");
spec = fsd.model.createDesignSpecification(struct("id","MY_SPEC", ...
    "targets",fsd.model.createSuspensionDesignTargets({t})));
% Generate native sweep/result separately; assemble a typed DesignCandidate.
% assessment = fsd.analysis.evaluateDesignCandidate(spec,candidate);
% fsd.analysis.validateDesignAssessment(assessment,spec,candidate);
```

Para cambiar una definición, tomar definitionSI, añadir metadata del registro
y pasar a su fábrica con unidades SI. No editar campos derivados/identity a
mano. save/load MAT conserva structs; round-trip probado.

## OPEN DECISIONS / límites posteriores

Las correcciones F-01/F-02/F-03 de auditoría se especifican abajo. No cambian
ecuaciones, unidades, signos, las 23 métricas ni la evaluación muestreada.

- Targets útiles, escalas, tolerancias, incertidumbres y prioridades físicas
  del monoplaza real: responsabilidad humana, no presets de v0.11.
- Fuente normativa vigente/verificada y aplicabilidad: Rules Engine futuro.
- Transformaciones de simetría de steering/roll y conectividad robusta de
  ramas más allá del índice conservador: especificar antes de ampliar.
- Evaluación/interpolación continua de resultados y propagación de
  incertidumbre: método y garantías pendientes; v0.11 es sampled.
- Nuevos bindings/métricas y síntesis inversa: sólo cuando haya modelos y
  ecuaciones aprobados. Un box nominal no garantiza packaging.

Permanecen futuros: generación razonada de targets, Performance Solver,
síntesis, optimización multiobjetivo, packaging 3D, anti geometry, ARB
INTEGRATED/POST_DESIGN/DISABLED, Tilt Test, robustez y Adams. No se inicia v0.12.

## Coherencia de un candidato — corrección F-01

Un candidato representa **una configuración física**, con cuatro esquinas
independientes, un vehículo y un load case cuando existen fuentes vehiculares.
No hay scope de escenario múltiple en este schema. Dos casos distintos no
pueden mezclarse silenciosamente; usar candidatos separados. La especificación
sí puede comparar candidatos diferentes bajo los mismos requisitos.

`createDesignCandidate` y `model.validateDesignCandidate` validan estructura,
modelos e identidad del registro: **no certifican coherencia conjunta de los
resultados**. Esto preserva model independiente de analysis. La frontera completa
es `analysis.validateDesignCandidate` / preparación de `evaluateDesignCandidate`:
primero reconstruye las siete fuentes con sus validadores nativos, después
comprueba las asociaciones físicas, antes de evaluar cualquier requisito.
Assessment validator, comparison, readiness, table y plot usan esa frontera;
un assessment antiguo o con HARD PASS manipulado no evita la reconstrucción.

Matriz de extracción desde objetos fuente verificados (no desde nombres):

| Familia | Geometría canónica por esquina | Otras identidades compartidas |
|---|---|---|
| BUMP | `geometryIdentity(model)` | Ninguna vehicular |
| RACK | `geometryIdentity(model.frontAxleGeometry.leftGeometry/rightGeometry)` | `model.identity`, steering FRONT |
| ROLL | `geometryIdentity(model.leftGeometry/rightGeometry)` | Sin sustituir una corner por el ID de eje |
| ACTUATION | `model.cornerGeometryIdentity` vía `model.identity` | ActuationGeometryIdentity por corner |
| MECHANICAL | `model.actuationIdentity.cornerGeometryIdentity` | ActuationGeometryIdentity y SpringDamperModelIdentity por corner |
| STATIC_LOADS | No depende de geometría de suspensión | `model.identity` de vehículo; `result.loadCase.identity` |
| GLOBAL_STATIC | `geometryIdentity(model.sources{i}.geometry)`, FL/FR/RL/RR | Vehículo, load case, actuation, springDamper, tire por corner y contexto global |

Vehículo y load case son dominios distintos: no se comparan identificadores de
tipos diferentes. La identidad vehicular incluye mass model, CG, gravity y
operatingConfiguration existentes; se exige igualdad canónica exacta, no
compatibilidad aproximada. El contexto global comprueba massApproximation,
unsprungPositionAssumption, masas efectivas, altura de carretera, frame y orden
de rotación. No compara solver options ni usa el árbol completo GlobalStaticSystem
como sustituto de identidades físicas: sus paths también incluyen las mallas.

Para cada par `(dominio, clave)`, todos los inputs físicos presentes deben
tener una única identidad canónica. Geometría, actuation y springDamper tienen
clave FL/FR/RL/RR; steering tiene FRONT; vehículo/load case tienen VEHICLE.
La asociación no inspecciona muestras ni re-resuelve mecanismos. Se ejecuta
una vez tras verificar fuentes, con un conjunto acotado de claves físicas.

`geometries` y `vehicle` siguen siendo opcionales. Si están presentes se añaden
al mismo mapa: fuente↔fuente y fuente→referencia obedecen la misma regla.
La aceptación/rechazo no depende del orden ni se elimina una fuente discrepante.
El mensaje `INCOMPATIBLE_SOURCE_ASSOCIATION dominio/clave` identifica los dos
owners en conflicto; el orden puede cambiar el orden de esos nombres, no el
resultado de validación.

Combinaciones válidas: dos BUMP de la misma geometría con sweeps diferentes;
BUMP+ACTUATION+MECHANICAL coherentes; fuentes distintas FL/FR y FRONT/REAR;
RACK+ROLL de la misma pareja; STATIC_LOADS+GLOBAL_STATIC del mismo vehículo/case;
candidato parcial, una fuente o ninguna. Son inválidas dos geometrías FL, un
eje con cualquiera de sus corners contradictoria, dos mecanismos/muelles
distintos para una misma corner, dos vehículos/cases distintos o una referencia
nominal contradictoria, incluso si todos los resultados individuales son válidos.

Las siete familias nativas exigen provenance canónica suficiente. Una fuente
sin evidencia requerida se rechaza: nunca se infiere compatibilidad por ID,
corner coincidente, valores iguales o source ID renombrado. El fallo estructural
se informa como `INVALID_CANONICAL_EVIDENCE`, preservando la excepción nativa
como causa. Los fallos de payload físico posteriores conservan su error nativo.
Ausencia de una fuente es diferente: deja su target NOT_EVALUATED, sin invalidar
fuentes independientes presentes. Una identidad verificable no es una firma
criptográfica ni prueba que una trayectoria ASSUMED sea físicamente realizable.

## Fidelidad del reporting gráfico — corrección F-02

Nominal y bandas se dibujan desde `target.definitionSI.x/value/tolerance/lower/upper`,
incluidos todos sus nudos interiores, en el orden declarado. Una tolerancia
escalar ya está expandida por la fábrica; también se admiten tolerancias por
nudo de curvas. Las líneas entre nudos son rectas, coherentes con interpolación
lineal declarada: sin smoothing, overshoot ni nudos procedentes del candidato.
VALUE_BAND y límites unilaterales siguen siendo comparaciones escalares según
su contrato; CURVE_BAND representa todos los límites por nudo.

Cada candidato conserva su malla evaluada, NaN, conectividad y muestras válidas.
El target completo puede dibujarse donde no existen resultados físicos; no se
oculta ni se rellena la curva actual. Leyenda: ID, status y domain coverage.
Cruces rojas indican únicamente incumplimientos demostrados en muestras;
panel inferior muestra desviación de esas mismas muestras. Esta presentación
**no cambia assessment.x, coverage, RMS ni SAMPLED_PASS**. Un target con pico
de 5 mm entre dos samples de 0 mm puede verse correctamente y seguir dando
SAMPLED_PASS: no se evaluó una muestra física en el pico.

## Contraste del reporting — corrección F-04

El nominal usa RGB sRGB `[0.5,0.5,0.5]`, trazo discontinuo de 2 pt y cuadrados
de 7 pt. Los límites usan `[0.45,0.45,0.45]` y trazos punteados de 1.5 pt;
las muestras/desviaciones usan el ciclo nativo MATLAB, círculos y 1.5 pt.
Son parámetros de presentación, no tolerancias ni constantes de ingeniería.
Los grises contrastan con blanco y con el fondo oscuro estándar R2025b sin
capturar colores de ejes que aún no han recibido su tema efectivo. No se usa
drawnow como solución ni callbacks de tema. El fondo/texto/ciclo de candidatos
siguen bajo control nativo MATLAB; no hay preferencias globales modificadas.

Validación: luminancia relativa sRGB y `(Lmax+0.05)/(Lmin+0.05)`; nominal
al menos 3.5:1, bandas al menos 3:1. El margen frente a 3:1 y mayor grosor
atienden antialiasing. Referencias de presentación:
[W3C contraste no textual](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html)
y [luminancia/contraste](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html).
No se reclama conformidad WCAG completa de una aplicación MATLAB.
Se comprueban colores finales y píxeles PNG, no sólo XData/YData.
`theme(fig,"dark")`/`theme(fig,"light")` son APIs locales verificadas en R2025b;
`DefaultFigureTheme` **no** admite SET/GET de default y no se usa.

La anomalía del primer lienzo automático documentada en F-04 se corrige en
F-05 mediante la política local siguiente; ya no requiere una operación manual
para obtener una primera exportación coherente de la API pública.
No se garantiza contraste sobre fondos personalizados ni distinción ilimitada
de candidatos cuando se repite el ciclo nativo.

## Apariencia local y márgenes — corrección F-05

`plotDesignTargetEvaluation` aplica `theme(fig,"dark")` **dentro de la API**,
inmediatamente después de crear cada figura y antes de tiledlayout/ejes/textos.
Es un fallback local determinista permitido por el alcance F-05. No se deduce
el tema de XColor, ni se usan callbacks, drawnow, settings internos o cambios
de preferencias globales. Se verificó que el getter theme devuelve inicialmente
Light Theme en el entorno oscuro y que `theme(fig,"auto")` antes de los ejes
todavía produce la mezcla incorrecta en el primer PNG. No se ha verificado un
getter público fiable del tema automático efectivo previo al renderizado.

**Política explícita:** estas figuras empiezan oscuras, incluso si la preferencia
global del usuario es clara. No se pretende heredar automáticamente esa
preferencia. El consumidor puede aplicar `theme(fig,"light")` o `"dark"` sobre
los handles devueltos, sin modificar otras figuras. Ambos temas se verifican.
No se recomienda volver a `"auto"` si se necesita la garantía F-05: se reabre
la inicialización automática nativa fuera de la política local probada.

La API MATLAB actualiza conjuntamente figure/layout/ejes/leyendas/textos:
sin asignaciones parciales de fondo ni paleta propia para cada superficie.
El PNG oscuro tiene margen/espacio entre paneles negro, textos `[217,217,217]/255`
y ejes `[18,18,18]/255`; el claro usa blanco y texto `[33,33,33]/255`.
La lectura real de píxeles exteriores mide contraste 14.877435:1 oscuro y
16.102192:1 claro. Se conserva el target `[.5,.5,.5]`, bandas y marcadores F-04.
Umbral de QA de texto pequeño 4.5:1; no es una tolerancia física ni certificación
WCAG de toda la aplicación. El oracle de PNG es específico del layout de
referencia de dos paneles y se complementa con inspección visual.

No hay cambio de layout general. Persiste un recorte superior parcial de la
etiqueta larga Ackermann del ejemplo, independiente del contraste/tema;
estado y severidad LOW documentados en el informe F-05. Otros tamaños, fuentes,
fondos personalizados o versiones MATLAB requieren validación propia.

## Diagnóstico mecánico — corrección F-03

Los gates existentes se conservan: convergencia, conditioning, feasibility,
disponibilidad de MR/Kw y finitud según la métrica. MR AVAILABLE no elimina
un límite mecánico excedido. `reasons` conserva un motivo primario por muestra
con prioridad determinista, de mayor a menor:

1. Fallo upstream: status exacto ActuationSweep o UNAVAILABLE_ACTUATION_FAILURE.
2. Conditioning del estado: UNAVAILABLE_ILL_CONDITIONED.
3. INVALID_SPRING_SEAT_GEOMETRY.
4. COIL_BIND_EXCEEDED.
5. DAMPER_TRAVEL_LIMIT_EXCEEDED.
6. Calidad específica de la métrica: MR status o wheelRateStatus; para
   UNAVAILABLE_MOTION_RATIO se conserva el motivo específico de MR.
7. Estado axial nativo; fallback genérico sólo si no hay motivo específico.

Las causas secundarias siguen recuperables en la fuente nativa completa.
COIL_BIND_LIMIT impide Kw conforme a v0.8, pero no invalida una fuerza axial
finita. SPRING_UNSEATED admite Fs/Kw cero según leyes nativas: no se inventa
un nuevo fallo. No se añaden límites, tolerancias ni leyes de contacto/bind.
