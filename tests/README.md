# Testing strategy

## v0.22 focused validation

Post-audit regressions: TestTireAuditUI exercises the three canonical Desktop
reproducers through Apply/Run/MAT; TestTireAuditDependencies checks structural
consumption and preserved provenance; TestTireAuditNumeric checks safe integer
normalization, rejection, readiness/evaluation and MAT. TestTireWorker additionally
rejects a reply from a physically reusable but unrequested tire revision.
See [subsequent audit corrections](../docs/v0.22-audit-corrections.md).

TestTirePhysics contains independent algebraic oracles; TestTireContracts covers
partial data, domains and frames. TestTireProject covers revisions, vertical
projection/STALE, MAT and canonical evidence. TestTireWorker uses a ProcessPool
and independently valid mismatched requests. TestTireUI uses native cell edits
and verifies draft ownership. TestTireMathWorksAdapter is optional: absence is
reported as skipped/incomplete, never PASS; its fixtures are synthetic provider
defaults, not FS measurements. No own TTC/MF fitting pipeline.
verifyV22 checks Analyzer/DAG/inventory only. [Actual results](../docs/v0.22-validation.md).

## v0.21 — global static integration

`TestGuidedGlobalStatic` tests native production paths, independent nominal
closure/load balance, CG world lever balances/reflection, four different mechanics,
readiness, no solution, full-content dependencies, tampering, response ownership,
receipt without forward solves, unit boundaries and MAT. `TestGuidedGlobalStaticUI`
drives real native controls; `TestGuidedGlobalStaticWorker` uses one real ProcessPool
for solve/MAT, cancellation, epoch discard and an alternate-vehicle response.
`verifyV21` checks Analyzer/DAG/inventory only; it does not claim suite execution.
Actual runs and exact counts are recorded in docs/v0.21-validation.md. Historical
oracles/tolerances remain unchanged. The two expected current software-version
assertions advance to0.21; no deleted test identity or relaxed numeric benchmark.
The existing GLOBAL_STATIC/CORNER negative case now expects INVALID_INPUT (wrong
scope), rather than UNSUPPORTED (engine now integrated); its test identity remains.

## v0.20 — guided actuation/mechanics

The six original TestGuidedActuationConfiguration cases are retained. New focused
classes: TestGuidedActuationAnalysis (native outputs/SI/semantic binding/no solves),
TestGuidedActuationSynthesis (declaration/annotations/budget/adoption/STALE),
TestGuidedActuationVariants (architecture/body declarations, tabulated units/sources,
axis contradiction/provenance), TestGuidedActuationUI (real controls/curves/drafts and
recovered plans), TestGuidedActuationPersistence (real ProcessPool, cancellation,
epoch/semantic rejection, exact MAT and integrated four-record example).

```matlab
setupProject; addpath('app','examples','tests');
r = runtests({'tests/TestGuidedActuationConfiguration.m', ...
    'tests/TestGuidedActuationAnalysis.m','tests/TestGuidedActuationSynthesis.m', ...
    'tests/TestGuidedActuationVariants.m','tests/TestGuidedActuationUI.m', ...
    'tests/TestGuidedActuationPersistence.m'});
assertSuccess(r);
report = verifyV20; % Analyzer, module DAG, inventory only; not full test execution
```

Run one MATLAB process at a time for native UI/worker tests. PCT is required for
the actual process test; no skipped worker check is reported as PASS. Historical
physics tests retain independent implicit rocker/energy/curvature oracles. Their
own tolerances are not replaced by GUI round-trip tolerances. Prior tests/examples
that write fixed output names must run in an isolated source copy to preserve old
evidence. New example takes an optional NEW destination and never overwrites it.

`verifyV20Legacy(input,expected,destination)` requires a real project produced by
unmodified0.19 in a separate MATLAB process and its exact expected value. It has no
missing-fixture fallback PASS. Ordinary tests do not depend on ignored work files.
All test identities, commands, successes, failed attempts, costs and unexecuted
coverage are distinguished in [v0.20-validation](../docs/v0.20-validation.md).

## v0.19 Packaging

TestPackagingGeometry uses independent Euclidean cases and optional Navigation
oracle; TestPackagingEvaluation consumes real native BUMP, including failed,
intermediate/rebound and missed-between-samples cases. TestPackagingProject
verifies canonical revisions, MAT and no implicit solves. TestPackagingPresentation
checks table round trips/invalid input and stored-geometry rendering.
TestPackagingUI exercises the native app workflow; a written test is not PASS.
TestProjectStorageValue checks exact classes/shapes/missing/Unicode, reserved-name
escaping, old/new MAT and tamper rejection. TestPackagingStorageAsync checks
actual background conversion, process-stage cancellation with foreign work and
staleness during decoding before MAT publication. Original TestGuidedDesignAsync
tests are retained, not replaced. Full-history GUI acceptance is separate from
small serializer probes; an earlier run was stopped for severe memory pressure.
`verifyV19` reproduces all17 prior examples and seven score/counter benchmarks
without relaxed expectations, adds packagingFeasibilityExample, Analyzer and DAG.
`benchmarkPackaging` explicitly measures serialization/transfer and deterministic
small/large batches in its own two-process pool; no production acceleration is
enabled by that diagnostic. Never run graphical/historical tests in parallel.
Use isolated copies because historical tests/examples write fixed output names.
[Actual runs, failures and pending checks](../docs/v0.19-validation.md).

## v0.18 Guided UI

`setupProject; r=runProjectTests;` conserva todos los nombres históricos.
Tests nuevos: TestGuidedDesignInputs (parser sin ejecución, unknown/rangos,
28 decisiones/corners y procedencia), TestGuidedDesignWorkflow (caso nativo7/7,
BUMP/gaps,configuración,MAT,adopción/STALE,compatibilidad de versión),
TestGuidedDesignAsync (procesos,snapshots,epochs,cancelación,ownership,errores,
MAT temporal y búsqueda completa) y TestGuidedDesignUI (`matlab.uitest`, app
auténtica,gestos,controles y gráficos reales). No ejecutar la suite en paralelo:
las pruebas gráficas/históricas comparten recursos y evidencias. Usar copia de
validación aislada para proteger MAT/PNG históricos. Resultados y límites en
[v0.18-validation](../docs/v0.18-validation.md); un test escrito no implica PASS.

## v0.17 Parametric Seed

`setupProject; r=runProjectTests; addpath("tests"); report=verifyV17;`.
TestParametricSeedInputs/Geometry/Project cubren decisiones ausentes, RULE/TARGET,
rangos, unidades, corners, matriz golden independiente, orientación/reflexión,
upright rígido, restricciones/degeneraciones, tres variantes, BUMP con gaps,
asociaciones, revisiones selectivas, persistencia y ataques a fuentes/MAT.
Expected de XYZ y distancias1e-14/1e-12m comprueban aritmética del fixture;
closure1e-8m y ángulos1e-12rad son controles de verificación, no fabricación.
Datos ASSUMED identificados; fuentes públicas independientes y no sólo el builder.
verifyV17 repite17 ejemplos/benchmarks, Analyzer/DAG/perfiles y nueve costes nuevos
tras warm-up. Baseline intacta y cifras realmente ejecutadas en
[informe](../docs/v0.17-validation.md), no inferidas del número de tests escritos.

## Corrección v0.16 V16-F-01: RULE no es input físico

`setupProject; addpath("tests"); verifyV16F01;` ejecuta 48 regresiones nuevas
en TestRulePhysicalInput, sin editar las 1516 pruebas de la baseline. Cubre las
18 cantidades conceptuales, rol separado de disponibilidad/source/confirmation,
RULE con referencias UNVERIFIED/VERIFIED (ficticias), TARGET/unknown/range,
ASSUMED/KNOWN/FIXED/DERIVED, selección explícita de rangos físicos, dependencias,
readiness/ejecución, inmutabilidad, revisiones selectivas, siete rutas de rechazo
de evidencia antigua y round-trips MAT. Perfil comprueba cero forwards/búsquedas
en readiness/validadores/MAT; recomputación algebraica nativa sigue permitida.

rulePhysicalInputFixture declara Mveh125kg, Mdriver64.8kg, EXCLUDES_DRIVER,
wb2.4m, tracks1.4/1.2m, CG[.9,0,.37]m, g9.7m/s², contactos explícitos y cierre
simétrico ASSUMED. Expected independiente: M189.8kg, W1841.06N y normales
[575.33125;575.33125;345.19875;345.19875]N, sólo si Mveh es dato físico explícito.
Con RULE la masa física y total están ausentes, STATIC_LOADS=MISSING_DATA.
AbsTol1e-12kg/1e-10N comprueba roundoff del fixture, no tolerancias de diseño.

legacyRuleEvidence codifica deliberadamente el defecto antiguo usando física
nativa genuina y sustituyendo sólo el concepto/contexto. No es API productiva.
`verifyV16F01("LEGACY")` se ejecutó ANTES del fix y comprobó igualdad completa
contra la ejecución pública antigua, ignorando únicamente cronómetros, además
de aceptación de derivación/resultado/proyecto/MAT. Después del fix ese modo
debe fallar: no modifica producción ni tiene un bypass para aprobar RULE.
Los tests nuevos no requieren ese MAT ni ningún output previo; crean/eliminan
sus MAT temporales con teardown. Evidencia de auditoría intencional bajo output.

Baseline del auditor:1516/1516 PASS en **23 bloques/procesos limpios** después
de timeout gráfico de steering en el intento monolítico. No confundir con un
monolítico concluido. El informe registra por separado el intento final de
`setupProject; r=runProjectTests` y su método real de cierre/cobertura por nombre.
[Informe focalizado](../docs/v0.16-validation.md#corrección-v16-f-01-rule-vs-physical-input).

Cierre de esta corrección: **48/48 focalizados** y **1564/1564 globales PASS**
(1516+48), Failed0/Incomplete0, monolítico limpio completado sin timeout ni
fallback segmentado. Cobertura anterior por nombre, sin faltantes/duplicados.
verifyV16 posterior:16/16 ejemplos,Analyzer0/519,DAG15,forwards ocultos0,
readiness sin búsquedas. Los cinco benchmarks v0.12–v0.15 mantienen contadores
y scores auditados. No cambios de tests anteriores, física ni controlador.

## Proyecto de ingeniería v0.16

`setupProject; r=runProjectTests; addpath("tests"); report=verifyV16`.
Baseline real1391/1391 PASS; tests anteriores se conservan salvo expected de
versión de Foundation. Nuevas clases VehicleConceptWorkflow,
EngineeringProjectWorkflow/Integrity/Integration prueban masas/CG/rangos/estados,
unidades, datos ausentes, identidad/revisión, doce capacidades, cuatro motores
delegados, oracles nativos independientes, perfiles sin forwards/búsqueda en
readiness, manipulación de snapshots/assessment/MAT y obsolescencia selectiva.
Known case explícito M270kg,g10m/s²,CGx.8m/wb1.6m:675N/corner bajo simetría
ASSUMED, no setup FS. Tolerancias verifican aritmética y equivalencia de llamadas
nativas (1e-10rad,1e-7N/m), no fabricación. Tests temporales tienen teardown.
El verifier mide ocho etapas tras warm-up, audita DAG/Analyzer y ejecuta16
ejemplos/regresiones. [Resultados e inventario](../docs/v0.16-validation.md).
Suite global final: **1516/1516 PASS**,1391 históricos+125 nuevos,
Failed0/Incomplete0. Nuevas clases:36/46/36/7 casos respectivamente.
Conservación histórica verificada por nombre contra la baseline, no sólo recuento.
`verifyV16` final:16/16 ejemplos,Analyzer0/515,DAG15,perfiles sin forwards
ocultos/búsquedas en readiness y ocho medianas tras warm-up en proceso limpio.

## v0.15 actuación inversa

`setupProject; results=runProjectTests; addpath("tests"); report=verifyV15`.
Baseline ejecutada1224/1224 PASS,14 ejemplos,Analyzer0/435,DAG10.
TestActuationSynthesisSpace/Physics/Integration/Reporting/Audit cubren roles XYZ,
eje YZ/XZ/CUSTOM y DOFs derivados, corners/arquitecturas, seeds y unidades,
FIXED/frozen/boxes, native rigid bodies/links, signos, inputs mecánicos y regímenes,
MR por diferencias finitas/derivación implícita, Kw total y resolución F01-1,
familias individuales/mixtas, HARD incompleto/fallido, budgets/cache/MAT,
26 ataques de contexto/evidencia/search, unknown rethrow y reporting PNG real.
No outputs previos necesarios para ejecutar tests desde un checkout limpio.
Expected geométricos y mecánicos independientes; MR AbsTol2e-5 y Kw .5N/m en
malla1e-4m documentan truncación del stencil, no tolerancias de fabricación.
Las pruebas de presentación verifican datos/gaps/inmutabilidad/perfil y PNG
oscuro/claro; revisión visual adicional registrada en el informe.
`verifyV15` repite 15 ejemplos y cuatro benchmarks v12/v13/v14, mide diez etapas
tras warm-up y verifica Analyzer/DAG/perfiles. [Resultados](../docs/v0.15-validation.md).
Resultado final: **1391/1391 PASS**,1224 históricos+167 nuevos, Failed0,
Incomplete0;15/15 ejemplos,Analyzer0/465,DAG10, perfiles0 forward solves ocultos.
Todos los tests requeridos se ejecutaron; no hay pruebas pendientes o omitidas.

## Auditoría v0.14 V14-F-01: SOFT exclusivamente RACK

`TestSteeringRackOnlyAudit` es una suite nueva independiente; no edita los
1195 tests anteriores. Usa el mecanismo ASSUMED de steeringSynthesisFixture,
rear reference 1.6 m y los cuatro targets RACK reales (headings FL/FR y
Ackermann a ambos signos de rack), o sólo los dos Ackermann. Tolerancia cero
en los SOFT es un control explícito de score no nulo, no un requisito FS.
El oracle escalar calcula el RMS ponderado de violaciones desde los ángulos
nativos, pesos y escalas originales, sin usar la proyección ni el RMS agregado
del assessment. AbsTol 1e-12 es verificación aritmética de la misma evidencia.

Incluye BUMP HARD satisfecho/fallido/indeterminado, SOFT excelente que no
rescata HARD FAIL, parcial/straight unavailable, controles mixtos/ROLL/HARD-only/
score desactivado, rechazo público sin SOFT, fuentes no soportadas, errores
recuperables/desconocidos, búsquedas deterministas, MAT y ataques de spec,
assessment, grids y opciones. Profile verifica cero solves durante validators,
assessment y comparación. Los tests gráficos históricos conservan la cobertura
de reporting sin solves; F-01 no modifica el sistema gráfico.

```matlab
setupProject;
newResults = runtests("tests/TestSteeringRackOnlyAudit.m");
results = runProjectTests;
addpath("tests"); report = verifyV14F01;
```

Evidencia RED y resultados finales en
[registro V14-F-01](../docs/v0.14-validation.md#corrección-de-auditoría-v14-f-01).
Resultados reales: baseline1195/1195, nueva suite29/29 y suite final1224/1224
PASS, Failed0,Incomplete0. verifyV14F01:14 ejemplos,Analyzer0/435,DAG10 y
hiddenSolves0. RACK-only E3/BUMP6/RACK3,score .0265716889609→.0238159165073;
benchmarks mixto v0.14 y v0.12/v0.13 intactos. MAT bajo output/v014-f01-*.mat.

## v0.14 steering synthesis

`setupProject; results=runProjectTests; addpath("tests"); report=verifyV14`.
Baseline real1064/1064 PASS,Failed0/Incomplete0,13 ejemplos,Analyzer0/408,DAG10.
TestSteeringSynthesisSpace/Physics/Integration/Reporting cubren endpoints XYZ,
montaje/fixed/bounds/simetría, mecanismos degenerados, nuevas fuentes BUMP/RACK/
ROLL, rack rígido/longitudes/signs/Ackermann, calidad con inner trasladado,
HARD/missing/gaps/score, cache/budgets, snapshots/attacks/MAT y PNG de ambos temas.
Expected físicos proceden de APIs nativas independientes; tolerancias1e-10rad,
2e-9m y rcond1e-12 son controles de verificación, no límites FS/fabricación.
Benchmark separado demuestra mejora alcanzable y tradeoff contra ideales cero.
Resultado final real:1195/1195 PASS,Failed0/Incomplete0,131 nuevos (45/36/41/9);
9 gráficos repetidos tras ajuste de constructor,14 ejemplos,Analyzer0/433,
DAG10 y perfiles sin solves ocultos. Evidencia MAT/PNG en el informe enlazado.
Los1064 históricos se mantienen; Foundation cambia sólo versión. Verificadores
de versión fija previos corresponden a sus tags. [Evidencia](../docs/v0.14-validation.md).

## v0.13 axle synthesis

`setupProject; results=runProjectTests; addpath("tests"); report=verifyV13`.
Baseline904/904 PASS. Historical expected físicos intactos; Foundation sólo
actualiza versión. Nuevos TestAxleSynthesisSpace/Physics/Integration/Reporting:
pares FRONT/REAR/24 coordenadas, simetría/bounds/FIXED, builders/F04/rethrow,
APIs físicas independientes y fórmula analítica ROLL, benchmark bilateral,
snapshots/fuentes/score/history/cache/selección/MAT, PNGs single/no-eligible/gaps.
Los tests usan datos ASSUMED, tolerancias de verificación, no targets FS.
verifyV13 mide pipelines físicos/costes/perfiles sin solves en validators/eval/
reporting y ejecuta13 ejemplos/Analyzer/DAG. Verificadores de versión fija previos
siguen disponibles en sus tags, no se alteran para aparentar compatibilidad.
[Contrato](../docs/axle-level-synthesis.md) · [Validación](../docs/v0.13-validation.md).

## v0.12 synthesis

`setupProject; results=runProjectTests; addpath("tests"); report=verifyV12`.
719 históricos de base v0.11 conservados, sin cambiar expected físicos.
Foundation actualiza versión; el test histórico de resize espera mounting y
propagación también en figuras ocultas, sólo después del primer PNG inmediato.
No se relajan asserts ni se añaden esperas de tema/resize a producción.
TestSynthesisSpace: bindings XYZ, inmutabilidad (incluido wheel axis no
seleccionado bit a bit), límites/fixed/boxes, spans y
round-trip, referencias inválidas. TestBoundedDirectSearch: expected matemáticos
independientes 1D/2D, frontera/plano/multimínimos/invalid/HARD/missing/budget,
multiseed/determinismo/cache. TestSynthesisIntegration: BUMP real, cambio de
HP/identity/fuentes/métricas y mejora alcanzable, guard Jacobiano contrastado
con derivadas centradas independientes, impossibles y ataques a todos los
campos reconstruibles/result replay, MAT/no hidden solves. TestSynthesisReporting:
PNGs nativos dark/light, fondo efectivo, oracle texto/target v0.11 y perfil cero
solves. Valores de fixture/perturbación son de verificación, no inputs FS típicos.

verifyV12 reutiliza verifyV08 sin modificar históricos: 12 ejemplos, Analyzer
de todos los .m y DAG; mide builder/validación/sweep/evaluación/iteración/search
y candidatos válidos/inválidos, warm-up y tres muestras. Guarda evidencia en
output (ignorado). Los verificadores con versión fijada v0.9–v0.11 permanecen
históricos. Engineering change → Unit test → Known case → Validation → Merge
(merge sólo con autorización humana; esta tarea no lo realiza).

### Auditoría v0.12 F-01/F-02/F-03

Los 813 tests iniciales se conservan sin ediciones durante estas correcciones.
TestSynthesisAudit: defaults independientes, opciones incompatibles/equivalentes,
plan/grid/geometry/spec/evidence/assessment y metadata coordinada, MAT, failure
records y ataques, presupuesto/cache/determinismo/inmutabilidad/no hidden solves.
El reproductor real tiene UBJ-LBJ paralelo Y, BUMP convergido y excepción nativa
DegenerateCasterProjection. synthesisFailureFixture BUILDER permite rechazo
collinear seguido de geometrías elegibles. synthesisAuditTestCall es fault
injection **privado**, prueba excepciones BUMP sin sweep y rethrow de errores
desconocidos/infraestructura; no acredita una ejecución física real.
TestSynthesisPlotAudit: single/failed/one eligible/many/no score/gaps/HARD failed,
oscuro/claro, objetos y PNG reales, targets/bandas/texto/score gaps, contratos
comparison/zero-budget y caso combinado failure→plot→MAT→plan tamper.

Sesiones MATLAB nuevas separadas, antes de cualquier figura:
`setupProject; addpath("tests"); verifyV12Audit("FIRST_SINGLE")` y
`setupProject; addpath("tests"); verifyV12Audit("FIRST_FAILED")`.
Después `setupProject; r=runProjectTests; addpath("tests"); verifyV12Audit`:
12 ejemplos, Analyzer/DAG, warm-up+tres mediciones de validators/failure/search/
single/multi plot y perfiles de invocaciones reales. PNG/MAT bajo output ignorado.
[Resultados e inventario](../docs/v0.12-audit-corrections.md).
Validación final real: **858/858 PASS**, Failed=0, Incomplete=0 (813 conservados
+45 regresiones), **12/12 ejemplos**, **0/375 .m** Analyzer, DAG9. Benchmark físico
E7/sweeps7/score0; search con cinco fallos: cinco invocaciones, validators0 solves.

### Corrección focalizada v0.12 V12-F-04

TestSynthesisZeroLengthLinks conserva los 858 tests previos y añade regresiones
UCA/LCA: evaluación individual, búsqueda, continuación, budget, cache, contadores
reales con profile, rechazo de manipulaciones, snapshot, MAT y PNG dark/light
sin elegibles. También cubre los pickups AFT. Expected IDs escritos aparte de
la política bajo prueba; mensajes contrastados con el validador nativo.
zeroLengthLinkFixture reproduce el prompt UCA y su equivalente LCA, con seed
admitido y límite en el ball joint. ALL_INVALID empieza collinear (rechazado
por builder, admitido por model) y después alcanza el link nulo. No se simula
un seed con link nulo como válido. zeroLengthBuilderFailureCall provoca una
excepción MATLAB real por field ausente dentro del core privado de BUILDER;
es sólo test de invariante rota/rethrow, no API ni hook de producción.

Ejecutar `setupProject; runProjectTests; addpath("tests"); report=verifyV12`.
Los tests nuevos se ejecutan también antes del fix para acreditar RED→GREEN.
La prueba principal conserva E7/sweeps7/Z .360,.340→.365,.345/score0 y reproduce
los tres casos principales F-01/F-02/F-03, sin repetir su implementación.
MAT/PNG bajo output/v0.12-f04-qa y output/v012-f04-*.mat (ignorados por Git).
Resultados finales en [informe](../docs/v0.12-audit-corrections.md#corrección-focalizada-v12-f-04).
Fase RED: 44/46 fallan por los abortos esperados. GREEN focalizado: **46/46 PASS**.
Suite final: **904/904 PASS** (858 previos+46), Failed=0, Incomplete=0; **12/12
ejemplos**, **Analyzer 0/378 .m**, DAG9. Código histórico y 858 tests sin ediciones.

## v0.11 requirements/targets/evaluation

`setupProject; results=runProjectTests` ejecuta toda la suite. `addpath("tests");
report=verifyV11` ejecuta 11 ejemplos, Analyzer en todos los .m, DAG, plots,
perfil y mediana de costes (warm-up y tres mediciones). No escribe resultados
ni hace commits. Verificadores v0.9/v0.10 con assert de versión se conservan
históricos; verifyV11 usa verifyV08 y los ejemplos más recientes sin falsearlos.

TestDesignDefinitions: roles/availability/scopes/SI, preliminary sin geometría,
FREE cerrado/incompleto, inválidos, provenance/RULE, identities/presentación,
MAT. TestDesignEvaluation: escalares/bandas/límites, linear/quadratic/
no uniforme/descending, RMS independiente, gaps/coverage, calidad c2 F-01,
MR firmado/installation abs/Fs/Fw/Kw, fuentes y ataques al assessment/target.
TestDesignIntegration: cinco métricas BUMP con traslación rígida conocida,
RACK/ROLL/ACTUATION nativos, STATIC_LOADS con/sin closure, global N500/CW.5/
referencia .095, tres categorías sin selección LOWEST_ENERGY_STABLE,
geometrías A/B con tradeoffs y restricciones distintas, dashboard y gráficos.

Fixtures prescritas 1-D son benchmarks matemáticos explícitos, no resultados
kinemáticos fabricados. designComparisonTestCall prueba sólo comparación
matemática con gaps internos/branch, no el validator de una fuente ficticia.
designCoreBenchmark mide el core privado con inputs prevalidos, no ofrece
una API pública que pueda omitir integridad. Ambos restauran pwd/path.
Tolerancias de expected están justificadas por roundoff o solver histórico,
no son recomendaciones de tolerancias de diseño de Formula Student.
La única edición de tests históricos v0.11 es expected version 0.11.0.
Resultados e inventario en [informe](../docs/v0.11-validation.md).

### Regresiones de auditoría F-01/F-02/F-03

Se preservan los 605 tests de la baseline v0.11; ninguna edición a sus expected.
`TestDesignCandidateAudit` cubre siete familias, ambas órdenes, registros
opcionales, corners/ejes independientes, vehicle/case, provenance ausente,
payloads coordinados, replay de assessment legacy y todas las APIs completas.
`TestDesignTargetPlotAudit` inspecciona XData/YData de objetos gráficos nativos:
pico de 5 mm, valle, descending, tolerancia por nudo, bandas/límites, cambios
de pendiente, mallas diferentes y orden, cobertura parcial y gap mecánico real.
`TestDesignMechanicalDiagnostics` comprueba coil exceso/frontera, travel,
unseating, MR/Kw/calidad, conditioning, fallo upstream y estados válidos.

`designAuditFixture` usa fuentes calculadas con APIs físicas reales y benchmarks
ASSUMED identificados. `designAuditTestCall("LEGACY_ASSESSMENT",...)` emula
deliberadamente el constructor antiguo sin asociación cruzada: sólo para probar
rechazo en el validator público, no es API de validación. Su modo de benchmark
aisla el coste del mapa usando inputs ya verificados, fuera de loops de muestras.
Las tolerancias de targets en tests son especificaciones adversariales explícitas,
no criterios de diseño de un FS. En grids minúsculos MR puede ser AVAILABLE y
fallar un target de 1e-9: nunca se relaja para esconder roundoff.

Ejecutar `setupProject; runProjectTests` y después `addpath("tests");
report=verifyV11Audit`. Este último conserva `verifyV11` histórico, ejecuta once
ejemplos, Analyzer/DAG/perfiles, mide warm-up + medianas y crecimiento 1–16
fuentes, y genera PNGs de QA en `output/v0.11-audit-qa` (ignorado por Git).
Los PNGs requieren además inspección visual; no sustituyen los tests gráficos.
Resultados e inventario: [correcciones](../docs/v0.11-audit-corrections.md).

## v0.10 global static equilibrium

F-01 de selección: TestGlobalStaticSelection añade 27 regresiones: políticas
de singleton, COIL_BIND_LIMIT, cardinalidades, energías válidas/inválidas,
empate exacto frente a un ulp distinto, deduplicación/orden, roots físicas
marginales y dos mínimos locales de distinta energía, ataques al validator,
MAT, plot sin selección y cuatro mecanismos reales bajo la política estable.
Los expected derivan del contrato, no del selector.
globalSelectionTestCall invoca el archivo privado de producción desde su
carpeta actual, restaurada con onCleanup: no copia lógica, no añade carpetas
private al path ni expone APIs de test en producción. Payloads mínimos son
tests aislados del selector, nunca resultados físicos válidos fabricados.
Los reproductores de integración usan factories/solve/validator públicos y
fuentes ASSUMED; verifyF01V10 informa las cuatro categorías únicas.

```matlab
setupProject; addpath("tests");
verifyF01V10;
runtests("tests/TestGlobalStaticSelection.m");
```

Engineering change → Unit test → Known case → Validation → Merge autorizado.
TestGlobalStaticEquilibrium: energía/gradient independientes, rotaciones/momentos
finitos, simétrico/pitch/roll/CW/compliance/mu, contactos y solve/failure.
TestGlobalStaticIntegrity: 17 payload attacks, unidades/IDs/datos no finitos,
masa desconocida/zero explícito, identidad física/metadata/MAT y fuentes.
TestGlobalStaticPathQuality: múltiples roots estable/no restauradora, tres
contactos marginales, F-01 con fuerzas disponibles/c2 no fiable, descending,
duplicados, límites/coil bind, fallo/NOT_ATTEMPTED/rama y mecanismos 3D reales.
Expected críticos analíticos, no obtenidos del solver bajo prueba.

```matlab
setupProject; results = runProjectTests;
addpath("tests"); report = verifyV10;
```

verifyV10 ejecuta los diez ejemplos, plots ocultos, Code Analyzer sobre todos
los .m, DAG y profiler sin solves/validaciones/modelos dentro del core energético;
timings de preparación/pp/U/gradient+H/solve/validation separados.
Los verifiers antiguos conservan checks de su versión; no se modifican para
fingir regresión de otra release. El expected version de foundation sí cambia
a0.10.0, única edición de tests históricos. [Informe](../docs/v0.10-validation.md).

## Regresiones de auditoría v0.9

TestStaticLoadAudit (16 métodos) cubre los tres reproductores, todos los
vértices/aristas, interior/exterior y roundoff, tracks diferentes, contactos
no rectangulares, gravity=5/10, conditioning, ambos límites CW, negativa
-5e-8 N, preservación exacta de 1e-12/1e-9/cero, discrepancias de medidas,
soporte negativo/irresoluble y ataques a los diagnósticos/familia/identity.
TestFlatIntervalAudit (9 métodos) comprueba N=21/101/501/2001, extremos
inclusivos, flats separados, roots aisladas a ambos lados, gaps por límites,
orden creciente/decreciente, dominio puntual y payloads manipulados.
Incluye un prefijo axial unseated seguido de fallo cinemático/NOT_ATTEMPTED:
el contrato histórico invalida MR del sweep y NO permite fabricar un flat.
Los 368 tests previos se conservan sin modificaciones.
Validación final real en R2025b: **393/393 PASS**, nueve ejemplos y Code Analyzer
**0 incidencias / 238 archivos**. No hay tests requeridos pendientes.

Expected de vértices: 1000 N sobre el contacto correspondiente; aristas:
500 N por contacto extremo. Expected fuera: no existe conjunto de normales
no negativas. Residuales se reconstruyen independientemente con coordenadas
y peso originales, tolerancia software 1e-9 N/Nm para los fixtures de escala
2 m/1000 N (NO define aceptación de viabilidad en producción).
La complejidad estructural verifica R comparaciones + como máximo F avances;
no exige ratios de tiempo exactos. verifyV09Audit mide API/core y el filtro
específico mediante profiler separado, con fuentes creadas antes del cronómetro.

```matlab
setupProject;
runProjectTests;
addpath("tests");
verifyV09;       % nueve ejemplos, Analyzer y DAG
verifyV09Audit;  % reproductores + mediana de 3 mediciones después de warm-up
verifyF01;       % curvatura irresoluble v0.8, no se modifica
```

## Cobertura v0.9

41 tests nuevos: VehicleParameters (12), StaticVehicleLoads (13),
CornerStaticEquilibrium (16). Baseline histórica 327; entrega inicial **368/368 PASS**
en MATLAB R2025b, antes de las 25 regresiones de auditoría. Resultados y mediciones en
[informe v0.9](../docs/v0.9-validation.md).
Sólo el expected version de foundation cambia a 0.9.0; ningún cálculo o
tolerancia histórica se modifica. Incluyen masas/CG/inventarios, falta de
datos, unidades/gravity, familia [250+d,250-d,250-d,250+d], CW y tracks distintos,
CG fuera de soporte, medidas/residual, sprung/unsprung, roots lineales y
cuadrática de compresión con múltiples roots/tangencia, preload, F-01,
límites/gaps/NOT_ATTEMPTED, mutaciones de payload e integración/figuras ocultas.
Referencias de cargas: 1000 N, L=2 m y tracks 1 m; roots lineales
F=300+7500*z N con z_eq=(330-300)/7500 m. Tolerancias 1e-10 N en álgebra,
1e-12 a 1e-14 m en roots de paths ideales; software, no tolerancias físicas.
Cuadrática c=.5*z-10*z² da F/k=.01-.15*z-15*z²+200*z³ y demanda 300 N:
roots z=0 y (15-sqrt(345))/400 m en el dominio usado, con slopes opuestos.
Tangencia exacta muestreada z=(30-sqrt(1260))/1200; no se promete detectar
una tangencia continua que la malla no resuelve.

Ejecutar setupProject; runProjectTests; addpath("tests"); verifyV09.
El verifier ejecuta los ocho ejemplos previos, el nuevo, Analyzer/DAG y
benchmarks con warm-up, fuentes resueltas fuera del equilibrio local.

## Corrección F-01 (v0.8 permanece 0.8.0)

`TestCurvatureReliability` añade 16 casos ejecutados (14 métodos, uno con tres
spacings parametrizados), sobre baseline 311: total 327. No altera pruebas
históricas. Comprueba sensibilidad de muestras, MR separado de curvatura,
cuadrática a 1e-13 m, rocker a 1e-4/1e-8/1e-9 m, cero bien resuelto, no uniforme,
descendente, preload/rate, cancelación, unseated/engagement, m/mm, nominal
irresoluble, cobertura parcial/plot NaN, gaps reales y ocho manipulaciones
adversariales de valores, status, weights, error, migración y agregados.

`tests/private/rockerWheelRateReference.m` calcula un círculo de suspensión y
cierre círculo/esfera del rocker independientes; deriva implícitamente theta
y la longitud del damper dos veces. No llama al solver ni al helper probado.
Referencia central z=0.01 m: Kw=433.730954102 N/m. Spacing 1e-4 m se compara
con AbsTol=0.03 N/m, por truncación del stencil; los spacings finos deben ser
indisponibles. Cuadrática exacta: Kw=13962 N/m, pero el input redondeado a
1e-13 m no puede recuperar fiablemente esa curvatura. El MR central se
compara con 0.56 (AbsTol=1e-5), no exige exactitud inexistente en esas muestras.
La equivalencia m/mm del estimador usa RelTol=0.01, por redondeo en conversiones.

```matlab
setupProject
results = runProjectTests;
addpath("tests")
reportV08 = verifyV08; % ocho ejemplos, Analyzer, dependencias y timings
reportF01 = verifyF01; % reproducciones, warm-up, mediana y perfil sin solves
```

Los budgets F01-1 son política numérica, no tolerancias físicas ni intervalos
estadísticos. No incluyen truncación; consultar la especificación mecánica.

## Cobertura v0.8

`TestSpringDamperModel`, `TestSpringDamperPhysics` y
`TestSpringDamperIntegration` añaden 39 tests significativos. Se conservan los
272 históricos; sólo cambia el expected version del test foundation a 0.8.0.
Cubren parámetros/identity/MAT, SI y unidades de frontera, muelle/preload/
asientos/unseating, transición, energía independiente, wheel rate completo,
MR constante/variable/negativo/cero, quadratic benchmark con malla uniforme,
no uniforme y decreciente, damping lineal/tabulado y potencias, límites,
derivadas indisponibles, gap real y tangencia real, manipulación de familias de
campos, fuentes de otro sweep/model, FL/FR/RL/RR, asymmetric travel, roll±,
steering+bump y nueve paneles gráficos ocultos.

Expected del benchmark: `c=a*z+b*z^2`, `MR=a+2*b*z`, `dMR/dz=2*b`,
`Fs=k*max(preload+c,0)`, `Fw=Fs*MR`, `Kw=k*MR^2+2*b*Fs` en engaged branch.
No se fabrica un ActuationResult: se usa la API de camino prescrito ideal.
Expected energéticos independientes usan diferencias centrales con h=1e-6 m,
errores admitidos 2e-6 N y 2e-5 N/m por truncación/roundoff. Benchmarks
cuadráticos usan 2e-13 para MR, 3e-10 1/m para dMR, 2e-7 N/m para Kw.
Son tolerancias de verificación numérica, nunca de fabricación.

Después de `setupProject; runProjectTests`, ejecutar `addpath("tests");
report=verifyV08` para ocho ejemplos, Code Analyzer sobre todos los .m,
timing de cuatro etapas (un warm-up + mediana de tres runs, 21 samples) y
perfil que comprueba cero llamadas a nonlinear/kinematic solvers durante
análisis mecánico. El perfil se separa de las mediciones de tiempo.

> Engineering change → Unit test → Known case → Validation → Merge

```matlab
results = runProjectTests;
```

La suite cubre:

- foundation y documentación;
- construcción estática m/mm, IDs, procedencia, reflexión, MAT y plot;
- tie rod y upright no collinear;
- rotation vector, ortonormalidad y transformación rígida;
- estado estático exacto;
- bump y rebound solicitados;
- conservación de cuatro links UCA/LCA y tie rod;
- rigidez interna del upright y wheel attachment;
- norma del wheel axis;
- simetría FL/FR y signo de camber;
- sweep, continuidad y round trip a cero;
- fallo explícito para travel imposible;
- plot estático/desplazado.
- toe analítico con toe-in/out y simetría por lado;
- aislamiento de toe frente a camber;
- steering axis LBJ→UBJ, caster XZ y kingpin inclination YZ;
- toe estático no nulo conservado y bump steer cero en traslación pura;
- fixture con bump steer de signo conocido, continuidad y reflexión FL/FR;
- correspondencia exacta sweep/análisis y propagación `NaN` de fallos;
- cinco curvas de análisis y unidades de presentación.
- identidad geometry/result y rechazo de diferencias de hardpoint de `1e-6 m`;
- invariantes `converged/status` y rechazo de statuses desconocidos;
- contrato completo de `SuspensionState`, payload fallido y redundancias;
- corner IDs char multirrenglón rechazados en APIs canónicas y wrapper legado;
- bump steer referenciado a estático en sweeps positivos, negativos y discontinuos sin cero.
- identity falsificada con offsets de `1e-6 m` en pivotes UCA, LCA y tie rod;
- rechazo de sweep con identity falsificada en cabecera y resultados;
- constraints físicos del payload contra la geometry identity declarada;
- `attempted` correcto para CONVERGED, NO_CONVERGENCE y NOT_ATTEMPTED;
- secuencia real continuation: convergidos, fallo y targets posteriores no intentados;
- equivalencia de camber entre primitiva `geometry` y wrappers públicos.

## Benchmark independiente

El fixture `TestBumpKinematics.benchmarkGeometry` usa brazos iguales con ejes paralelos y tie rod compatible. Todos los puntos rígidos se trasladan sobre un arco de radio `0.3 m` sin rotación. Para travel `w`, el expected value es:

```text
deltaY = 0.3 - sqrt(0.3^2 - w^2)
R = I
camber = 0
```

La expectativa se deriva del círculo, no de la salida del solver.

En v0.3 se asigna toe estático conocido al mismo fixture. Como `R=I`, el wheel axis no rota: toe permanece constante y bump steer debe ser cero independientemente de la implementación de análisis.

## Fixture independiente de bump steer

Se baja `TIE_ROD_INBOARD` 50 mm respecto a `TIE_ROD_OUTBOARD`, manteniendo los brazos del benchmark. Al desplazarse el upright, la longitud fija del tie rod obliga una rotación: el fixture produce toe-in en rebound y toe-out en bump con la convención X hacia atrás. Los tests comprueban signo, cero estático, continuidad y reflexión lateral; no generan el expected value llamando de nuevo a la función probada.

Los tolerances angulares de los tests analíticos son `1e-14 rad`. Las comparaciones que atraviesan `fsolve` usan `2e-8 rad`, coherentes con las tolerancias existentes del benchmark v0.2 y no representan tolerancias de fabricación.

Los tests sin cero verifican directamente `bumpSteer=toe-staticToe`, además de comprobar que ni el primer target ni el target más próximo a cero se convierten en referencia implícita.

## Cobertura v0.4

- contratos FRONT `FL/FR` y REAR `RL/RR`, orden lateral e identity de eje;
- wheel stagger y geometría deliberadamente asimétrica;
- restricción cinemática desde `u × (B-Paxis)` y reducción al método clásico;
- ejes interiores 3D oblicuos, pivot order y regresión contra el antiguo
  atajo de seccionar el plano del brazo;
- velocidad de UBJ/LBJ alrededor de `20 mm` por diferencia central del solver
  (`h=1e-5 m`) y FVIC independiente obtenido resolviendo las dos restricciones
  de velocidad;
- benchmark exacto simétrico: IC `±0.1 m`, `Z=0.25 m`, RC `Z=13/44 m`;
- benchmark asimétrico: `Y_RC=-247/3020 m`, sin forzar centerline;
- rueda circular ideal, radio, ortogonalidad y rechazo de datum incompatible;
- IC infinito, coincidente y restricciones degeneradas;
- intersecciones homogéneas, casi paralelas y conditioning explícito;
- líneas de construcción con IC infinito, incluidos RC finito y RC infinito;
- composición de heave, continuation bilateral y simetría de `Y_RC`;
- rechazo de resultados intercambiados, axle identities mezcladas y análisis
  de puntos sin convergencia bilateral, con payload fallido completamente
  inválido y sin datos dinámicos clonados del estado estático;
- plots de vista frontal y migración en unidades de presentación.

## Cobertura v0.5

- construcción FRONT, identity, unidades m/mm, rack oblicuo y rechazo de eje
  trasero o joints coincidentes;
- compatibilidad exacta `rack=0` con `solveBump` para distintos wheel travels;
- traslación rígida de ambos inner joints y conservación de separación;
- cierre combinado con wheel travel asimétrico y rack travel;
- round trips `0 -> +rack -> 0` y `0 -> -rack -> 0`;
- heading/road-wheel angle analíticos y wrapping alrededor de ±pi;
- intersección de steering axis finita, paralela y condicionamiento;
- scrub y mechanical trail cero, positivos, negativos y espejo FL/FR;
- Ackermann clásico ideal con ICR común, parallel steering, signo del error a
  ambos lados del ideal, near-straight, static toe y wheel stagger;
- curvas toe/bump-steer preservadas con rack cero;
- giros espejo para racks opuestos, contactos y métricas laterales;
- rack imposible, payload `NaN`, Ackermann inválido e integrity mismatch;
- fallo unilateral FL/FR: invalida ambos lados del análisis, conserva
  diagnostics individuales y propaga `NaN` en sweeps sin reutilizar datos;
- rechazo de un rack sweep manipulado antes de entrar al core privado;
- sweep ordenado, análisis agregado y cinco visualizaciones en unidades de
  presentación.

Los expected de heading, scrub, trail e ICR se obtienen mediante geometría
analítica y relaciones independientes, no realimentando outputs del solver.

`TestV04GoldenRegression` añade referencias numéricas generadas con MATLAB
R2025b desde el commit v0.4.0
`6cf64c5c0a23d4c4deb396681a8dfdf2d2f4443d`, anterior a la generalización del
solver. Cubre FL a 0/+20/-20 mm, FR a +20/-20 mm y una geometría 3D a +12 mm;
compara UBJ, LBJ, tie-rod outboard, Wheel Center, wheel axis, camber y toe sin
llamar a `solveBump` actual como expected.

## Cobertura v0.6

- pares asimétricos `[+15,-10]`, `[-12,+8]`, `[+20,+5] mm`, FRONT/REAR,
  constraints por lado, sweep ordenado e identity;
- regresión `solveAxleTravel([z,z])` contra `solveAxleHeave`;
- base ortonormal de carretera, líneas normalizadas, distancia firmada y
  degeneración/inversión de contactos;
- benchmark exacto de traslación circular con Delta derivado en
  `docs/equations.md`, independiente de `fzero`;
- residual de cierre para roll positivo/negativo, heave cero/no cero,
  equivalencia deg/rad y signo `phi>0 => zLeft>0,zRight<0` en fixture espejo;
- round trips pasando por cero con heave cero/no cero y paridades espejo de
  travel, camber, toe, RC y tracks;
- camber road-relative manual para FL/FR con wheel axes verticales;
- altura RC road-relative por evaluación manual de `aY+bZ+c` y conservación
  explícita del status histórico `CONTACT_LEVEL_MISMATCH`;
- root no bracketed, heave imposible, payloads NaN, targets/identities
  manipulados e incompatibilidad entre axles;
- integración con `solveSteering` usando wheel travels de roll y rack no cero;
- plots de front view inclinada y curvas de camber, RC y track.
- regresión near-limit a `h=0.197541687 m`, `phi=0.1 deg` y
  `Delta≈0.000526305367 m`;
- bracket normal, endpoint inválido unilateral en cada lado, conservación del
  último dominio válido, raíz no bracketed, dominio insuficiente y root exacta
  en el centro sin `fzero`;
- sweep `[0,4,0] deg` con `CONVERGED/ROOT_NOT_BRACKETED/NOT_ATTEMPTED`, status
  cinemático preservado, status de análisis separado y todos los agregados
  fallidos en `NaN`.

## Renderizado v0.11 F-04

`TestDesignTargetRender` añade 16 casos: ambos temas, visible/oculta, pico,
valle, candidatos con mallas distintas en ambos órdenes, cobertura parcial y
gaps internos. Exporta PNG reales, verifica contraste final, presencia de
píxeles de target/bandas/candidatos, leyenda/etiquetas y datos sin cambios.
Los PNG de unit tests usan tempname y se eliminan mediante teardown.
Se oculta el toolbar **sólo en figuras de QA** para que el hover del ratón no
contamine la captura o introduzca un warning. No se cambian preferencias.

La suite normal **no prueba por sí sola la primera figura de una sesión nueva**.
Ejecutar estos comandos separadamente desde la raíz, cada uno en un proceso
MATLAB nuevo (PowerShell/terminal; no dentro de una sesión gráfica previa):

```text
matlab -batch "setupProject; addpath('tests'); verifyV11FirstTargetExport('auto');"
matlab -batch "setupProject; addpath('tests'); verifyV11FirstTargetExport('dark');"
matlab -batch "setupProject; addpath('tests'); verifyV11FirstTargetExport('light');"
```

`auto` exige un entorno cuyo tema automático efectivo sea oscuro; lo verifica
después de exportar, sin editar preferencias permanentes. Los otros dos usan
`theme(fig,...)`, disponible y verificado en R2025b, únicamente sobre la primera
figura creada por el plot. Cada proceso comprueba primera y segunda exportación,
ausencia de warnings, pico/bandas originales y evaluación inalterada; perfila
el plot para detectar solves ocultos. Evidencias deliberadamente conservadas en
`output/v0.11-f04-qa` (ignorado por Git), no scripts temporales incorporados.
El helper mide luminancia sRGB: nominal >=3.5:1, bandas >=3:1, y confirma en
el PNG RGB los colores efectivos del fondo y trazos con margen de cuantización
de 2/255. Inspección visual complementaria, no certificación de accesibilidad.

La anomalía del lienzo exterior/etiquetas observada en F-04 se corrige en F-05
con la política local documentada abajo, separada del contraste del target.
La evidencia F-04 precedente se conserva como histórica.
Validación final 10 octubre 2026: 716/716 PASS (700 anteriores + 16 nuevos),
Failed=0, Incomplete=0; tres procesos nuevos de primeras/segundas exportaciones
completados, sin warnings de exportación en esas pruebas.

## Fondos exteriores y texto v0.11 F-05

Se conservan los 16 casos F-04 y se amplían con `designExteriorTextCheck`:
PNG real leído con imread, fondo dominante por región exterior y mediana de
píxeles de texto efectivos (margen RGB 2/255), contraste sRGB >=4.5:1 y al menos
20 píxeles de texto en cada región. Regiones normalizadas `[xmin xmax ymin ymax]`
del PNG de dos paneles: título/exponente `[0 1 0 .035]`, margen Y `[0 .07 0 1]`,
etiqueta/ticks X `[0 1 .94 1]`, gap/ticks `[0 1 .40 .55]`. Son ventanas de QA
de un caso conocido, no reglas de ingeniería ni detector universal de texto.
También se verifican XColor/YColor/ZColor sobre el fondo efectivo de cada eje.
Se complementa con inspección visual: no OCR, no garantía semántica pixel a pixel.

Tres nuevos tests: API sin cambio manual de tema visible/oculta con dos
candidatos y resize real; control negativo que conserva los glifos grises y
blanquea el lienzo PNG, exigiendo `fsd:tests:ExteriorTextContrast`. No se duplica
el conjunto de tests de datos F-02. Contraste target/bandas sigue verificándose
con el helper F-04 sin modificarlo. Todos los PNG temporales usan teardown.

Ejecutar cada comando en un proceso **nuevo**, antes de cualquier figura:

```text
matlab -batch "setupProject; addpath('tests'); verifyV11FirstFigureText('auto','off');"
matlab -batch "setupProject; addpath('tests'); verifyV11FirstFigureText('auto','on');"
matlab -batch "setupProject; addpath('tests'); verifyV11FirstFigureText('light','off');"
matlab -batch "setupProject; addpath('tests'); verifyV11FirstFigureText('dark','off');"
matlab -batch "setupProject; addpath('tests'); verifyV11FirstFigureText('auto','off','MULTI');"
matlab -batch "setupProject; addpath('tests'); verifyV11FirstFigureText('auto','off','PARTIAL');"
matlab -batch "setupProject; addpath('tests'); verifyV11FirstFigureText('auto','off','GAP');"
```

`auto` significa que el test **no** llama a theme: usa directamente la API en
el entorno automático oscuro original, sin cambiar preferencias. La API aplica
su propio fallback oscuro local; el resultado final ya no usa ThemeMode auto.
Light/dark explícitos se configuran sólo para esos escenarios. Cada proceso
comprueba primera exportación inmediata, resize 1100×700→900×600, PNG realmente
de dimensiones distintas y segunda figura tras exportación previa. Para resize
visible, se deja montar la ventana **después** de la primera exportación y se
sincroniza el frontend con drawnow/pause(1), sólo en QA; no es una solución de
tema ni se espera antes del primer PNG, lo que podría ocultar el defecto.
WindowState/WindowStyle normal se aplican sólo a esa ventana de QA.

Evidencias deliberadamente conservadas en output/v0.11-f05-qa, ignorado por Git.
El verificador falla en rojo con producción anterior por contraste 1.411534:1,
sin ayuda de theme desde el test. F-01/F-02/F-03 se ejercitan separadamente en
114 tests focalizados (62+18+15+19), además de la suite completa.
Validación final: **719/719 PASS**, Failed=0, Incomplete=0 (716 históricos
conservados + 3 nuevos), **114/114 focalizados** y siete procesos nuevos de QA.
La primera exportación visible se verifica sin espera previa; sólo se espera
después para resize. Sus PNG finales cambian realmente de 1154×787 a 949×685.

## Cobertura v0.7

- modelo, units, identities y canonicalización de axis line;
- equivalencia cinemática PUSHROD/PULLROD con identities distintas;
- attachments UPRIGHT/UCA/LCA e invariantes de eje, distancia y round trip;
- rocker YZ/XZ/CUSTOM, rigidez, closure y signo orientado;
- roots múltiples, continuation unwrapped, tangencia de ambos signos y por
  tolerancia, no-intersection y reconstrucción independiente de rama;
- sweeps bump/rebound, round trips, asymmetric axle, body roll y steering;
- MR analítico independiente, spacing uniforme/no uniforme estrictamente
  monótono, referencia estática solicitada, migración, stroke y rocker range;
- validación autónoma de `SteeringCornerResult` antes de consumirlo;
- invalid payloads, mezcla de geometrías y propagación NaN;
- visualización de estado y cuatro curvas de análisis.

## RF-03 operation/result binding

`TestGuidedOperationSemantics` compares the immutable owner operation with genuine
canonical alternative results/configurations, including the two independently
reported RF-03 cases. Rejections compare the complete project/session and exact
MAT round trips; positives cover serial/process execution and multi-corner BUMP.
`TestGuidedPackagingBinding` adds canonical candidate-index, physically equal
SEED/CANDIDATE relabelling and alternate sampled-parent/grid regressions.
`TestGuidedResponseProtocol` retains RF-01/RF-02 malformed-envelope/policy and
char/string regression coverage. These use explicit synthetic cases, not vehicle
performance assumptions. MATLAB R2026b and local ProcessPool/PCT are required
for the worker cases; absence must be reported, not counted as PASS.

```matlab
setupProject; addpath('app');
results = runtests({'tests/TestGuidedOperationSemantics.m', ...
                   'tests/TestGuidedPackagingBinding.m', ...
                   'tests/TestGuidedResponseProtocol.m'});
assertSuccess(results);
```

See [RF-03 contracts and actual evidence](../docs/v0.19-rf03-operation-contract.md).

## V21-F-01 pending native tires

`TestGlobalStaticPendingTires` covers each missing corner and all four missing,
exact preservation of existing rows/paths/provenance, complete configuration,
retry of the same project after an injected final-render failure, and native
MAT load / real FR cell edits / Apply / READY / GLOBAL_STATIC / Save / Load.
`GlobalStaticRenderController` is a presentation-only fault-injection double;
the end-to-end case uses the actual View and Controller. No solver is mocked.
Run with `setupProject; addpath('app','tests','examples');
r=runtests('tests/TestGlobalStaticPendingTires.m'); assertSuccess(r);`.
Focused related regressions and actual results are recorded in
[the correction report](../docs/v0.21-f01-validation.md).
