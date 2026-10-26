# Requisitos

## v0.23 — Anti-Roll Bar & Axle Coupling

- REQ-V23-PLAN-PRESERVATION (V23-F-02): Apply sin edición conserva exactamente
  la declaración canónica ARB, clases, dimensiones, celdas, campos ausentes,
  metadatos y opciones no representados. No crea revisión ni invalida resultados
  vigentes. Una edición convierte sólo su campo desde unidades visuales y mantiene
  la invalidación existente de los consumidores afectados; sin tolerancias de
  equivalencia ni cambios en hashes/worker. Revertir al texto cargado preserva
  el valor original. MAT conserva la declaración antes y después.

- REQ-V23-SIZING-UNITS (V23-F-01): valid integer/single/double sizing targets
  display in Nm/deg after double promotion, with sufficient round-trip precision.
  Apply without edits preserves the loaded canonical plan/target/provenance;
  intentional numeric/provenance edits remain effective. Partial plans remain
  editable/persistible. Do not reject valid integers to avoid presentation errors.

- REQ-V23-RESOURCE: representaciones equivalente/coaxial separadas, revisión,
  eje/puertos/ajustes, referencias libres, dominios y procedencia; parcial guardable.
- REQ-V23-ENERGY: una energía acoplada, signos de trabajo virtual, fuerzas/gradiente,
  Hessiano cruzado y rigidez geométrica; sin esfuerzo físico inventado en equivalente.
- REQ-V23-CLOSURE: ROCKER/UPRIGHT MUST y UCA/LCA si reutilizables; pickup ARB
  independiente del amortiguador, continuidad/rama/residuo/condicionamiento/límites.
- REQ-V23-REFERENCE: UNKNOWN, ZERO_AT_INSTALLATION y DECLARED_FREE distintos;
  instalación descargada no significa universalmente ángulo libre cero.
- REQ-V23-SECTION: rigidez conocida y GJ/L excluyentes; maciza/tubular, inverso
  determinado con target del usuario, sin optimización ni validación resistente.
- REQ-V23-MOTION: muestras pareadas/BUMP y ROLL nativo; ningún producto cartesiano,
  extrapolación, clipping ni supuesto de roll–steer–bump general.
- REQ-V23-GLOBAL: acoplamiento energético de0/1/2 ejes en siete coordenadas;
  mantener Newton/contacto/selección y regresión sin barra; no fuerzas internas
  duplicadas en balances externos, rueda sin contacto aún conectada a la barra.
- REQ-V23-STABILITY: candidato de curvatura separado de tangente bilateral
  disponible; no certificar estabilidad en extremos/discontinuidades/singularidades.
- REQ-V23-PACKAGING: radios/soportes/obstáculos explícitos y checks seleccionados;
  INCOMPLETE/colisión/clearance muestreado diferentes; no certificado continuo.
- REQ-V23-TRACE: historial inmutable, consumo STALE selectivo frente a identidad
  exacta de ejecución; revisión físicamente reutilizable no puede recibir otro run.
- REQ-V23-UI: crear/editar parcial, readiness, estudiar/comparar/dimensionar,
  packaging, asignación por eje, GLOBAL_STATIC con/sin ARB e historial/MAT desde Desktop.
- REQ-V23-STORAGE: RF01–03/epochs/cancelación/worker y MAT auténtico0.19–0.22,
  sin migración física ni reinterpretación de evidencia histórica.
- REQ-V23-VALIDATION: oráculos independientes, regresiones relacionadas,
  Analyzer/DAG/inventario, tiempo/RAM y persistencia representativos. Evidencia
  de desarrollo distinta de auditoría independiente y de validación experimental.
- REQ-V23-DOC: ecuaciones, convenciones, métodos, alternativas, supuestos,
  límites, casos y evidencia reproducibles. ARB-001 INTEGRATED permanece abierto.

## v0.22 — Tire Models Foundation

- REQ-V22-PARTIAL: Geometry Only/Generic/Custom y parámetros desconocidos guardables;
  sin coeficientes físicos automáticos, calidad distinta del nivel de información.
- REQ-V22-PHYSICS: DUGOFF_REDUCED_1 exacto, signos/dominios explícitos, carga/camber
  declarados, combined slip, oráculos independientes y datos sintéticos identificados.
- REQ-V22-API: capacidades/readiness por operación y evaluación N muestras sin
  producto cartesiano; NaN/estados distinguen desconocido/no soportado/fuera dominio.
- REQ-V22-LIBRARY: revisiones inmutables y asignaciones compartidas a cuatro esquinas.
- REQ-V22-GLOBAL: conservar ley vertical histórica; fuente exclusiva, dependencia
  proyectada para que cambios de fuerza no invaliden equilibrio vertical.
- REQ-V22-TRACE: historial/MAT/worker/RF01–03; exactitud de recurso, revisión,
  canales, hipótesis, orden y dominio antes de recibir una respuesta.
- REQ-V22-UI: flujo Tires con edición incompleta, escenarios, curvas/modelo claramente
  identificados, comparación condicionada y persistencia; conservar V21-F-01.
- REQ-V22-OPTIONAL: MathWorks sólo mediante APIs públicas y adaptador opcional,
  modelo proveedor distinto del nativo, sin datos importados certificados por defecto.
- REQ-V22-CANONICAL-UI: abrir request predeterminado, cualquier orden de canales
  admitido y plan vacío sin mutar declaraciones; completar, ejecutar y recuperar MAT.
- REQ-V22-REUSE: compatibilidad por parámetros/leyes/estados/canales consumidos,
  separada de la identidad completa de ejecución y de la recepción RF-01/02/03.
- REQ-V22-NUMERIC: normalizar enteros reales seguros y single a double en la
  fábrica; validación, readiness, evaluación e identidades MAT coherentes.

Contrato: [tire-models-foundation](tire-models-foundation.md).

## v0.21 — Global static setup

- REQ-V21-FOUR: cuatro esquinas explícitas e independientes; construir RL/RR
  con constructores existentes, sin generar ni reflejar datos silenciosamente.
- REQ-V21-READY: identificar recursos, masas/CG, neumáticos y planes ausentes o
  incompatibles sin solves durante preparación; no convertir ausencia en cero.
- REQ-V21-GLOBAL: integrar el sistema/solver nativo0.10 con pose común, trayectorias
  nuevas y completas en reposo, neumáticos unilaterales y gravedad/energía históricas.
- REQ-V21-EVIDENCE: conservar intentos, alternativas, selección y diagnósticos;
  distinguir convergencia, admisibilidad y estabilidad evaluada. Sin selección,
  ninguna pose nominal sustituta. Presentación mm/deg/N/Nm/J, SI interno.
- REQ-V21-TRACE: vinculación semántica RF-01/02/03 de operación a contexto completo;
  rechazo de configuración alternativa antes de mutar la sesión/historial.
- REQ-V21-STALE: geometría, actuación, mecánica, tire, masa/CG y planes/opciones
  relevantes invalidan sin borrar. Datos ajenos no producen STALE innecesario.
  Comparación histórica muestra revisión/estado.
- REQ-V21-UI: recorrido sin editar estructuras MATLAB, usando Vehicle/Geometry/
  Actuation existentes y sección Global static; feedback y elección worker/sync.
- REQ-V21-MAT: historial/referencias exactos al SAVE/LOAD y compatibilidad anterior.
- REQ-V21-VERIFY: oráculos independientes, worker real, casos inválidos/contacto,
  UI real, Analyzer/DAG/inventario, tiempo/memoria representativos, sin inventar PASS.

Contrato: [guided-global-static.md](guided-global-static.md). Evidencia por caso:
[v0.21-validation.md](v0.21-validation.md). No predicción dinámica ni ingeniería
estructural/fabricación, ARB, neumáticos de prestaciones o v0.22 implícitos.

## v0.20 — actuación y mecánica operativas

| ID | Requisito vigente | Verificación principal |
|---|---|---|
| REQ-V20-CONFIG | Geometría registrada, PUSHROD/PULLROD, attachment UPRIGHT/UCA/LCA, eje/rocker explícitos y coilover opcional nativo; parámetros, límites, unidades y procedencia | TestGuidedActuationConfiguration (seis originales), TestGuidedActuationVariants |
| REQ-V20-ANALYSIS | Ejecutar ACTUATION/MECHANICAL, mostrar compresión/longitud/theta/MR/fuerzas/Kw total con validez y diagnósticos; velocidad mecánica explícita | TestGuidedActuationAnalysis, TestGuidedActuationUI, oráculos históricos |
| REQ-V20-SEARCH | Configurar especificación/plan/opciones y ejecutar síntesis histórica con suspensión fija; comparar candidatos guardados sin nuevos solves | TestGuidedActuationSynthesis, TestGuidedActuationUI |
| REQ-V20-ADOPT | Adoptar recursos relacionados exactos, elegibilidad/compatibilidad verificadas, una revisión, geometría e histórico intactos y STALE selectivo | TestGuidedActuationSynthesis, TestGuidedActuationPersistence |
| REQ-V20-RECEIPT | Vincular operación solicitada a respuesta real; reutilizar RF-01/02/03, preservar IDs/epochs y rechazar respuestas canónicas de otra operación atómicamente | Tests nuevos de configuración/análisis/síntesis/persistencia; regresiones RF |
| REQ-V20-UI | Extensión mínima de v0.19, unidades de ingeniería, borradores explícitos, estados/readiness/error, worker o selección síncrona explícita; no inputs inventados | TestGuidedActuationUI y regresiones UI/worker |
| REQ-V20-MAT | Persistir configuración/escenarios/procedencia/opciones/historial exactos; leer proyectos anteriores y permitirlos sin nuevos recursos | TestGuidedActuationPersistence, verifyV20Legacy, regresiones de proyecto/storage |
| REQ-V20-QA | Tests relevantes por incremento, oráculos independientes, regresión histórica, APIs públicas, Analyzer/DAG y costes representativos reales; auditoría separada | verifyV20 y el informe de ejecución |
| REQ-DOC-CONTINUITY | Cada versión debe actualizar contratos, arquitectura, datos, decisiones, requisitos, tests, validación y roadmap afectados; explicar ecuaciones/algoritmos/supuestos/alternativas/errores/límites y evidencia sin depender de chats | Documentación por versión y registro central estable |

No Direct Acting en0.20 (requisito FSD-DIRECT conservado), nueva estructura/fatiga/
pandeo/hidráulica avanzada/fabricación, cuatro esquinas integradas, ARB o Adams.
La existencia de sus módulos/APIs históricos no implica flujo guiado completo.
Registro central = estado/planificación; requirements = requisitos; decisions =
razones; contratos = funcionamiento; informes = ejecuciones; originales = historia.
[Contrato](guided-actuation-mechanics.md) · [registro](development-register.md) ·
[evidencia real](v0.20-validation.md).

## v0.19 Packaging & Physical Feasibility

- REQ-V19-SOLIDS: esfera/cápsula/AABB/OBB explícitas, transformaciones propias,
  unidades SI, material frente a espacio libre y procedencia sin dimensiones ocultas.
- REQ-V19-DISTANCE: separación/testigos exactos para pares admitidos; broad-phase
  no sustituye narrow-phase; no profundidad de penetración inventada.
- REQ-V19-COVERAGE: nominal/BUMP almacenado, fallos y datos ausentes visibles;
  ningún CLEAR ante cobertura requerida incompleta ni garantía entre muestras.
- REQ-V19-PROJECT: recursos versionados, MAT retrocompatible, staleness selectivo,
  comparaciones seed/candidato sin cambiar score, HARD, elegibilidad o controlador.
- REQ-V19-UI: tablas editables, selección de pares/muestras, 3D, históricos/STALE,
  persistencia nativa y operaciones largas por el worker de procesos existente.
- REQ-V19-VALIDATION: oráculos analíticos, estados reales, regresión, ejemplos,
  Analyzer/DAG, integridad y costes secuencial/paralelo documentados sin falsos PASS.

[Contrato](packaging-physical-feasibility.md) y [ejecuciones](v0.19-validation.md).

## v0.18 Guided Design Interface

- REQ-V18-APP: shell auténtico editable/guardable/ejecutable App Designer R2026b;
  controles de workflow dinámicos separados del núcleo.
- REQ-V18-FLOW: proyecto parcial -> datos explícitos ->28 decisiones -> DW/3D ->
  BUMP explícito -> targets/variables -> síntesis nativa -> comparación -> MAT.
- REQ-V18-TRUTH: unknown no es cero; RULE no es dato físico; no midpoint,
  targets óptimos, física nueva ni resultados precalculados como ejecución.
- REQ-V18-STATE: escenarios/ledger nativos, adopción explícita, revisión y STALE.
- REQ-V18-ASYNC: procesos con snapshots/IDs/epochs, un escritor, cancelación real
  y cierre seguro; sin paralelizar búsqueda histórica sin ganancia demostrada.
- REQ-V18-QA: pruebas de inputs/workflow/worker/UI reales, equivalencia nativa,
  regresión completa, ejemplos, Analyzer, integridad y revisión visual documentadas.
[Alcance detallado](guided-design-interface.md) · [Ejecución](v0.18-validation.md).

## v0.17 Concept-to-Seed

- REQ-V17-INPUT: concepto/definición progresivos, roles y unidades nativos,
  decisiones identificadas, sin promoción RULE ni midpoint.
- REQ-V17-BUILD: corners4/FRONT simétrico o independiente, líneas UCA/LCA,
  offsets upright, referencias de contacto y transformaciones rígidas nativas.
- REQ-V17-STAGES: readiness/nominal/sampled independientes; BUMP explícito.
- REQ-V17-CONSISTENCY: MATCH/MISMATCH/UNKNOWN/NOT_APPLICABLE, frames/dimensiones/
  wheel datum, tolerancia numérica documentada y boxes/FIXED nominales nativos.
- REQ-V17-PROJECT: escenarios deterministas, adopción y origin binding, revisiones
  selectivas, histórico inmutable, MAT revalidado sin solves.
- REQ-V17-SEED: uso directo por síntesis histórica, steering opcional explícito,
  sin actuación/targets/prestaciones ficticias.
- REQ-V17-QA:1564 históricos, oracles/adversariales nuevos,17 ejemplos,
  Analyzer/DAG/perfiles/costes; resultados reales en informe.
[Contrato](concept-to-seed.md) · [Evidencia](v0.17-validation.md).

## v0.16 Vehicle Concept & Engineering Project Workflow

- REQ-V16-CONCEPT: concepto parcial, masas sin doble cómputo, estados/unidades/
  procedencia/rangos/confirmación explícitos y derivaciones mediante v0.9.
- REQ-V16-PROJECT: Concept/Scenario/Result separados, corners opcionales,
  recursos nativos asociados, identidades/revisiones y ledger inmutable.
- REQ-V16-READINESS: doce acciones adaptadas, diagnósticos concretos y estados
  READY/MISSING_DATA/INVALID_INPUT/UNSUPPORTED/BLOCKED_BY_DEPENDENCY; sin solves
  ni búsqueda oculta, ni inferencia de seeds/gravedad/CG/targets óptimos.
- REQ-V16-EXECUTION: cuatro síntesis y análisis públicos históricos delegados,
  specs HARD/SOFT originales, evidencia validada y obsolescencia selectiva.
- REQ-V16-MAT: schema explícito, validación al guardar/cargar, rechazo de
  asociaciones/manipulaciones incoherentes, MAT históricos intactos.
- REQ-V16-QA: baseline1391, nuevas pruebas independientes/adversariales,
  16 ejemplos, Analyzer/DAG/perfiles/costes, física/controlador/main intactos.
  Sin commits/merge/tag/release/v0.17, nuevos modelos/UI/certificación.
  [Contrato](vehicle-concept-project-workflow.md) · [Validación](v0.16-validation.md).

## v0.15 Actuation Geometry & Motion Ratio Synthesis

- REQ-V15-SPACE: una suspensión fija y seeds ACT/MECH coherentes; FL/FR/RL/RR,
  PUSHROD/PULLROD, cinco roles nominales, FIXED/RANGE/FREE/boxes/frozen y SI.
- REQ-V15-BUILD: reconstrucción física atómica por fábricas nativas, eje con
  dos DOFs/dirección fija, geometría de suspensión intacta, cambios/identidades.
- REQ-V15-PHYSICS: BUMP→actuación nuevos, rigid rocker/rod/attachments,
  MR/travel/angle y mecánica tangente nativos; no nueva hidráulica/fallback.
- REQ-V15-ASSESSMENT: spec original completa ACT-only/MECH-only/mixta/HARD-only;
  HARD antes de score/disponibilidad, pesos/escalas explícitos, gaps no PASS.
- REQ-V15-EVIDENCE: contexto numérico/mecánico, sources, quality y replay/MAT
  coherentes; caché local exacta, fallos cerrados, unknown rethrow, contadores reales.
- REQ-V15-QA: 1224 históricos conservados, tests independientes/adversariales,
  15 ejemplos, Analyzer0, DAG, perfiles sin solves ocultos, PNG claro/oscuro y costes.
  Sin commit/merge/tag/release/main/v0.16, CAD ni certificación estructural.
  [Contrato](actuation-geometry-synthesis.md) · [Evidencia](v0.15-validation.md).

## v0.14 Steering Geometry & Ackermann Synthesis

- REQ-V14-MECHANISM: FRONT FL/FR/steering seeds explícitos coherentes, pickups y
  joints tie rod XYZ autorizados, FIXED/RANGE/boxes/simetría, reconstrucción atómica.
- REQ-V14-PHYSICS: BUMP L/R y RACK nuevos sobre el mismo mecanismo; ROLL centrado
  opcional; longitudes/rack rígidos, rear reference explícita, sólo adapters nativos.
- REQ-V14-EVALUATION: un assessment, HARD prioritario, cobertura/calidad separadas,
  SOFT normalizado con pesos explícitos y tradeoffs físicos sin ganador inventado.
- REQ-V14-PROVENANCE: snapshots/model identities/planes/options/grids/reference/
  límites/spec y cache ligados; validators/MAT/reporting sin solves; unknown rethrow.
- REQ-V14-CONTROLLER: boundedDirectSearch único, budgets/history/cache intactos,
  contadores BUMP L/R/RACK/ROLL distintos de evaluaciones y closures internos.
- REQ-V14-QA: baseline1064 conservada+nuevas regresiones, benchmark modifique
  realmente steering,14 ejemplos,Analyzer0,DAG,PNG claro/oscuro sin leyendas sobre datos.
  No commit/merge/tag/release/main/v0.15 ni certificación CAD/normativa/fabricación.
  [Contrato](steering-geometry-synthesis.md) · [Evidencia](v0.14-validation.md).

## v0.13 Axle-Level Suspension Synthesis

- REQ-V13-SPACE: dos seeds FRONT/REAR, frame común, 24 coordenadas posibles,
  FREE/RANGE/FIXED/boxes/SI/provenance, simetría seleccionada sin DOFs duplicados.
- REQ-V13-BUILD: reconstrucción bilateral atómica, hardpoints autorizados,
  identities individuales/conjunta, fallos F04 sin solves y seeds inmutables.
- REQ-V13-PHYSICS: BUMP real por lado; ROLL nativo con plan/heave explícitos;
  targets sólo de adaptadores reales, gaps/calidad preservados y unsupported explícito.
- REQ-V13-JOINT: un assessment, HARD/availability/quality separados, pesos sólo
  explícitos, ningún ganador con score o HARD incompleto.
- REQ-V13-SEARCH: controller v0.12 único, deterministic budgets/cache/history;
  contadores de candidatos distintos de sweeps/cierres físicos internos.
- REQ-V13-EVIDENCE: snapshots ligados a ambos modelos/planes/spec, validators y
  replay sin solves, ataques/MAT/reporting single/no-eligible/PNG verificables.
- REQ-V13-VALIDATION: baseline904, nuevos tests, mejora bilateral real, benchmark
  analítico de roll, trece ejemplos, Analyzer0/DAG, solvers/APIs históricos intactos.
  Sin commit/merge/tag/release/main/v0.14. [Contrato](axle-level-synthesis.md).

## v0.12 Inverse Suspension Synthesis

- REQ-V12-SPACE: seed inmutable, FREE/RANGE/FIXED v0.11, XYZ inboard/SI,
  límites finitos/boxes y normalización reversible según resolución double.
- REQ-V12-BUILD: sólo cambios autorizados, fábrica/validators originales,
  identidad nueva, brazos no degenerados; sin certificar CAD/fabricación.
- REQ-V12-PIPELINE: BUMP/camber/toe/bumpSteer/caster/KPI reconstruidos realmente;
  otros targets rechazados antes del search, sin fuentes seed obsoletas.
- REQ-V12-QUALITY: fuentes nativas completas, gaps/convergence/static reference,
  guard de rama/conditioning; ningún candidato incompleto presentado factible.
- REQ-V12-SEARCH: polling determinista/multiseed/budget/stops/cache exacto;
  HARD antes de score SOFT explícito, sin ganador cuando no hay puntuación.
- REQ-V12-TRACE: records/attempts íntegros, MAT, validators/replay sin solves,
  cambios HP/comparación/plots con garantías v0.11.
- REQ-V12-F01: snapshot de opciones BUMP efectivas ligado a problema/record/
  evidencia; reject planes incompatibles incluso al cargar MAT, sin re-solve.
- REQ-V12-F02: allowlist por etapa, fallos conservados/no elegibles/score NaN,
  evidencia disponible y presupuesto correcto; unknown/infrastructure rethrow.
- REQ-V12-F03: trace/diagnósticos con una evaluación o sin elegibles; plot single
  sin comparación artificial; PNG/contraste/primera sesión y contratos nativos.
- REQ-V12-VALIDATION: 719 históricos conservados, benchmarks independientes,
  mejora física alcanzable, casos imposibles/ataques, 12 ejemplos, Analyzer0/DAG.
  Sin commit/merge/tag/release/main ni v0.13.

[Contrato](inverse-suspension-synthesis.md) · [Evidencia](v0.12-validation.md).

## v0.11 Design Requirements, Targets & Evaluation

- REQ-V11-PARAM: ocho roles compatibles, siete disponibilidades, unknown vacío,
  provenance explícita y RULE estructurada sin normativa incorporada.
- REQ-V11-SPACE: FREE/RANGE sin defaults; cierre exige bounds/binding; fixed
  con tolerancia explícita y box nominal XYZ cerrado, sin colisiones CAD.
- REQ-V11-TARGET: seis tipos completos, catálogo real, scopes/units/coordenadas
  y condiciones estáticas tipadas; simetría explícita limitada.
- REQ-V11-EVAL: consume resultados originales verificados una vez por fuente,
  sin solves ni mutaciones; errores/normalización/score explícitos.
- REQ-V11-COVERAGE: NaN/statuses/gaps, no extrapolación, RMS domain-weighted,
  sampled distinto de continuous; HARD demostrado invalida incluso parcial.
- REQ-V11-CANDIDATE: identidades y asociaciones, comparación sin ganador,
  readiness/prerrequisitos; event priorities sólo metadata.
- REQ-V11-CANDIDATE-F01: fuentes canónicas coherentes entre sí por corner,
  vehículo y load case, aun sin registros nominales; rechazo previo a cualquier
  assessment, independiente del orden, sin rutas públicas completas alternativas.
- REQ-V11-PLOT-F02: target/bandas desde todos los nudos originales; muestras,
  gaps y cobertura independientes por candidato; sin cambiar semántica sampled.
- REQ-V11-DIAGNOSTIC-F03: causas mecánicas específicas con prioridad documentada,
  sin promover disponibilidad ni modificar límites o física v0.8.
- REQ-V11-INTEGRITY: reconstruct validators, MAT, ataques, benchmarks analíticos,
  fuentes reales y selección global F-01 sin alternatives{1} implícita.
- REQ-V11-VALIDATION: 471 históricos + suite nueva, 11 ejemplos, Analyzer0,
  DAG/perfil/costes/diff check; no commits/tags/merge/v0.12.

Contrato e implementación en [especificación](design-requirements-target-evaluation.md),
evidencia de ejecución en [informe](v0.11-validation.md).
Correcciones de auditoría: [informe específico](v0.11-audit-corrections.md).

## v0.10 Coupled Chassis Pose & Global Static Equilibrium

- REQ-V10-POSE: siete DOF, R finita Rx*Ry coherente, sin yaw/translation XY.
- REQ-V10-TIRE: ley opcional vertical unilateral explícita, sin N negativa.
- REQ-V10-MASS: cuatro mu conocidas o cero autorizado; CG suspendido derivado
  y mu en WC móviles, sin doble gravedad ni NaN→0.
- REQ-V10-ENERGY: única U, gradient coherente con pp, springLaw v0.8 reutilizada,
  balances world actuales y CW emergente, no un cierre impuesto de v0.9.
- REQ-V10-PATH: producción 3D real, fixed-inboard; segmentar gaps/ramas/límites,
  no extrapolación/re-solves; MR vs fuente y c2 F-01 independiente.
- REQ-V10-SOLVE: scaled Newton limitado, tolerancias dimensionales explícitas,
  multistart/alternativas/deduplicación, conditioning, límites artificiales.
- REQ-V10-STABILITY: Hessiano global fiable o NOT_EVALUABLE, transiciones sin
  bilateral ficticio, mínimos/marginales/no restauradoras diferenciadas.
- REQ-V10-VAL: 393 históricos intactos (excepto expected version), benchmarks
  independientes/payload adversarial, diez ejemplos, Analyzer0, DAG/perfil/timings.

Alcance y límites efectivos en [contrato](global-static-equilibrium.md),
evidencia real en [informe](v0.10-validation.md). No v0.11.

## v0.9 Vehicle Parameters, Static Loads & Corner Equilibrium

- REQ-V09-MASS: TOTAL_MASS/COMPONENT_MASSES excluyentes, inventarios disjuntos,
  gravity explícita, composición CG XYZ y unknown preservados; SI/MAT/provenance.
- REQ-V09-LOAD: balances vertical/longitudinal/lateral con contactos reales;
  rango/nullspace, no negatividad, familia y límites sin cargas únicas inventadas.
- REQ-V09-CLOSE: measured/CW/ASSUMED symmetry explícitos, sin clipping físico;
  CW=(FR+RL)/(M*g), residual de medidas conservado y viabilidad/uniqueness.
- REQ-V09-SUPPORT: sprung/unsprung no duplicados; demanda local sólo con datos,
  sin aero/anti ni equivalencia a fuerzas exactas en links.
- REQ-V09-EQ: path v0.8 validado en reposo, todos los cruces resolubles,
  roots/flats/ausencia explícitos, sin extrapolar/gaps ni elección estable implícita.
- REQ-V09-QUALITY: fuerza con MR válido puede producir root con Kw desconocido;
  conservar F-01 y estabilidad local no evaluable, sin afirmar pose global.
- REQ-V09-VAL: referencias independientes, payload adversarial, 327 históricos,
  nueve ejemplos, Analyzer cero, DAG, perfil sin nuevos solves y timings.

Especificación: [Vehicle Parameters & Static Load Equilibrium](vehicle-static-equilibrium.md).

### Correcciones de auditoría v0.9

- REQ-V09-F01: reconocer vértices/aristas factibles con intervalos puntuales a
  resolución de roundoff; verificar candidatos y separar dimensión admisible
  del grado de libertad algebraico. CG exterior más allá del presupuesto se rechaza.
- REQ-V09-F02: no negatividad separada del residual de balance; conservar CW
  original, candidato diagnóstico y soporte NaN cuando inviable. Soporte negativo
  nunca se recorta; signo irresoluble tiene diagnóstico explícito y demanda NaN.
- REQ-V09-F03: mediciones SI idénticas al input canónico, sin snapping ni ajuste.
- REQ-V09-F04: filtrado de roots/flats O(N log N) como máximo, sin alterar gaps,
  extremos, orden, roots aisladas ni estabilidad. Medir filtro aparte de fuentes.
- REQ-V09-AUDIT-VAL: conservar los 368 tests anteriores y nueve ejemplos;
  añadir regresiones independientes y adversariales para los cuatro hallazgos.

## v0.8 Spring, Damper & Wheel-Rate Modelling

- **REQ-SD-001:** modelo COILOVER opcional por esquina, SI y MAT, independiente
  de UI y de contratos geométricos, con identidad física completa.
- **REQ-SD-002:** muelle compresión-only, precarga no negativa, asientos con
  offset firmado, gap y energía; no convertir preload en corner load/sag.
- **REQ-SD-003:** `Fw=Fs*MR`, `Kw=k*MR^2+Fs*dMR/dz`; conservar ambos términos
  y rigidez negativa con diagnóstico, no una afirmación de estabilidad global.
- **REQ-SD-004:** derivada segunda directamente desde c(z), achieved travel,
  mallas no uniformes/invertidas, extremos y estados no disponibles explícitos.
- **REQ-SD-005:** damping por velocidad axial firmada, branches independientes,
  pasividad/potencia; sin mezclar damping con wheel rate.
- **REQ-SD-006:** tablas piecewise linear pasivas con origen (0,0), sin
  extrapolación ni requisito artificial de monotonicidad de fuerza.
- **REQ-SD-007:** límites opcionales, UNKNOWN si ausentes; coil bind y damper
  exceeded no extrapolan end-stop laws ni publican fuerzas factibles ficticias.
- **REQ-SD-008:** single-state axial-only; sweeps validan fuentes completas,
  velocidades y asociación sin re-resolver suspensión/rocker.
- **REQ-SD-009:** gaps/ill-conditioning/transiciones conservan NaN; referencia
  nominal sólo con target cero único y wheel rate válido.
- **REQ-SD-VAL-001:** tests independientes cuadrático/MR constante, preload,
  energía/derivadas, damping con MR negativo, límites, unidades, tablas,
  integridad, cuatro corners, asymmetric travel, roll y steering.
- **REQ-SD-VAL-002:** 272 tests históricos, ocho ejemplos, Code Analyzer,
  dependency audit, diff check y benchmark warm-up de 21 samples.

El [contrato detallado](spring-damper-wheel-rate.md) fija los statuses y APIs.
F-01 añade requisitos de fiabilidad numérica, sin cambiar las leyes físicas:

- **REQ-SD-F01-001:** estimar sensibilidad desde pesos del stencil y resolución
  de las muestras originales c/z, no sólo rcond o eps de la derivada final.
- **REQ-SD-F01-002:** criterios separados para MR, curvatura intrínseca e impacto
  en Kw; presupuestos mixtos absolutos/relativos documentados, sin ocultar
  cancelación ni curvatura irresoluble detrás de fuerza/preload pequeños.
- **REQ-SD-F01-003:** suprimir c2, término geométrico y total no fiables con NaN
  y status explícito; preservar respuesta axial, fuerzas/damping de rueda y
  componente elástico si MR y sus leyes/límites son válidos.
- **REQ-SD-F01-004:** nominal/migración/extrema/plots no reciclan valores
  invalidados; cobertura parcial explícita, sin interpolación de gaps.
- **REQ-SD-F01-005:** validadores reconstruyen también sensibilidad/statuses,
  weights, cobertura y agregados; rechazan payloads adversariales.
- **REQ-SD-F01-VAL:** reproducir cuadrática a 1e-13 m y rocker a 1e-4/1e-8/1e-9 m
  con referencia analítica independiente; casos cero, mallas irregulares y
  descendentes, unidades, preload, gaps reales y regresión histórica completa.

No incluye ARB, anti geometry, equilibrio, dinámica, optimización, reglas,
packaging, Adams ni App Designer. Las exclusiones siguientes son históricas
por milestone, no exclusiones de las capacidades mecánicas actuales.

## v0.5 Steering

- **REQ-STR-001:** aceptar únicamente un `AxleGeometry` FRONT con FL/FR.
- **REQ-STR-002:** definir el rack desde los dos inner tie-rod joints y admitir
  un eje 3D oblicuo no degenerado.
- **REQ-STR-003:** trasladar ambos joints la misma distancia sobre el eje sin
  rotación ni compliance.
- **REQ-STR-004:** resolver wheel travel y rack travel prescritos conservando
  las cinco longitudes físicas y la rigidez del upright.
- **REQ-STR-005:** mantener compatibilidad numérica con `solveBump` en rack
  cero y con las APIs v0.1–v0.4.
- **REQ-STR-006:** aplicar continuation determinista wheel-travel-first y
  rack-second; los sweeps siguen el orden solicitado.
- **REQ-STR-007:** publicar resultados vinculados a una identity completa y no
  publicar métricas válidas cuando falle una esquina.
- **REQ-ANA-001:** separar road-wheel angle, deflexión desde estático,
  rack-induced steer, toe y bump steer.
- **REQ-ANA-002:** calcular scrub/trail con steering axis y contacto geométrico
  actuales, con signos definidos en `conventions.md`.
- **REQ-ANA-003:** analizar Ackermann por ICR sobre `X=rearAxleX`, admitir
  static toe y wheel stagger, y tratar near-straight sin distancias ficticias.
- **REQ-VAL-001:** cubrir casos analíticos, bump+steering, round trip, simetría,
  fallos, integridad y regresión histórica.

## Fuera de alcance v0.5

Steering wheel/column, pinion ratio, fuerzas, compliance, pneumatic trail,
body roll, full vehicle, anti-geometry, actuación, packaging, rules,
neumáticos de fuerzas, dinámica, optimización, Adams y App Designer.

## Notas

Los requisitos físicos y fórmulas detalladas se fijan en `conventions.md`,
`equations.md` y `decisions.md`; este documento solo mantiene trazabilidad de
alcance.

## v0.6 Body Roll

- **REQ-ROLL-001:** aceptar wheel travel prescrito `[left,right]` en FRONT y
  REAR, reutilizando el solver de esquina.
- **REQ-ROLL-002:** conservar `solveAxleHeave` y sus schemas históricos como
  wrapper del recorrido general.
- **REQ-ROLL-003:** definir `phi` por mano derecha alrededor de `+X` y exigir
  `abs(phi)<pi/2` para orientación inequívoca de carretera.
- **REQ-ROLL-004:** definir `h=(zLeft+zRight)/2` y resolver Delta mediante
  `nRoad dot (CR-CL)=0` con contactos geométricos actuales.
- **REQ-ROLL-005:** usar root solve escalar bracketed, diagnostics y
  continuation heave-first/roll-second.
- **REQ-ROLL-005A:** construir el bracket con muestras válidas de cada lado de
  forma independiente, refinar transiciones valid→invalid y priorizar la rama
  local más próxima al estado anterior.
- **REQ-ROLL-006:** admitir sweeps ordenados positivos, negativos y cruzando
  cero sin reordenar inputs.
- **REQ-ROLL-007:** distinguir target road line y solved contact line, con
  residual y error angular dentro de tolerancia para convergencia.
- **REQ-ROLL-008:** detectar contacto coincidente/invertido, root no bracketed
  y fallo cinemático sin publicar estados válidos.
- **REQ-ROLL-009:** separar `kinematicStatus` de `analysisStatus` y conservar
  métricas agregadas `NaN` en failures y targets no intentados.
- **REQ-ROLL-ANA-001:** publicar camber chassis-relative y road-relative sin
  cambiar la definición histórica de camber.
- **REQ-ROLL-ANA-002:** reutilizar FVIC/RC v0.4 y añadir altura perpendicular
  a road line sin cambiar `rollCenterHeight_m`.
- **REQ-ROLL-ANA-003:** distinguir wheel-center track, contact track sobre la
  carretera y cambios respecto a `h=0,phi=0`.
- **REQ-ROLL-VAL-001:** cubrir benchmark cerrado, residual, round trip,
  simetría, asimetría, unidades, fallos, identities y steering integration.

## Fuera de alcance v0.6

Cierre simultáneo steering+roll, Ackermann en frame road-aligned, full vehicle,
pitch, fuerzas, muelles, ARB, actuation, longitudinal anti-geometry, dinámica,
optimización, packaging, rules, Adams y App Designer.

## v0.7 Actuation Geometry & Kinematics

- **REQ-ACT-001:** modelo opcional por esquina con PUSHROD/PULLROD y bodies
  UPRIGHT/UCA/LCA.
- **REQ-ACT-002:** rocker axis 3D orientado, presets YZ/XZ y CUSTOM.
- **REQ-ACT-003:** transformar attachments con el rigid body fuente sin
  re-resolver la suspensión.
- **REQ-ACT-004:** cierre analítico robusto, roots explícitas y continuation
  local unwrapped.
- **REQ-ACT-005:** distinguir no-intersection, underconstrained, degeneraciones,
  tangencia y fallo cinemático fuente.
- **REQ-ACT-006:** publicar theta, damper length/compression, residual y
  conditioning con identities y validadores físicos.
- **REQ-MR-001:** MR canónico `dCompression/dWheelTravel`, installation ratio
  absoluto y gain angular separado.
- **REQ-MR-002:** diferencias finitas de segundo orden no uniformes; derivada
  no disponible con menos de tres estados o si la coordenada no es estrictamente
  monótona; el orden de entrada nunca se corrige automáticamente.
- **REQ-MR-003:** migración referida exclusivamente al target solicitado de
  wheel travel exactamente cero.
- **REQ-ACT-007:** validación independiente de coeficientes, tangencia,
  candidatos, rama continuation, conditioning y payload geométrico.
- **REQ-ACT-008:** un `NOT_ATTEMPTED` posterior a fallo no invoca el closure ni
  arrastra diagnósticos del estado anterior.
- **REQ-ACT-VAL-001:** benchmarks independientes UPRIGHT/UCA/LCA,
  YZ/XZ/CUSTOM, roots múltiples, tangencia, no-solution, steering, roll y
  asymmetric travel.

## Fuera de alcance v0.7

Fuerzas de muelle/amortiguador, preload, bump rubber, wheel rate completo,
ARB, anti-dive/lift/rise/squat, full vehicle, pitch, tire forces, dinámica,
optimización, packaging, rules, Adams y App Designer.
