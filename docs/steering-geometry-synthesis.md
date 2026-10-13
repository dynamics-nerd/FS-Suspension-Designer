# v0.14 — Steering Geometry & Ackermann Synthesis

## Inspección previa: dependencias nativas

Inspeccionado antes de ampliar variables: DoubleWishboneGeometry v0.2, sus
fábricas/validators; SteeringSystemGeometry y steering/rack v0.5; BUMP v0.2/0.3;
AckermannGeometry; adaptadores RACK v0.11 y síntesis v0.12/v0.13.

- `FL/FR_TIE_ROD_OUTBOARD` es un punto material rígido del upright, junto con
  UBJ, LBJ, Wheel Center y Contact Patch. Los tres primeros definen un upright
  no degenerado; mover el pickup reconstruye ese cuerpo y sus cierres.
- `FL/FR_TIE_ROD_INBOARD` es fijo en BUMP y joint de rack en steering. Las
  longitudes estáticas se derivan de endpoints, no son otro input independiente.
- `createSteeringSystem(frontAxle,rearAxleX,'m')` reconstruye el rack desde ambos
  inboards: eje orientado izquierda→derecha, separación `norm(PR-PL)`.
  `Pcurrent=Pstatic+q*axisDirection` para ambos lados; no hay rotación ni dos
  movimientos independientes. Rack oblicuo está permitido por el modelo nativo.
- `solveRackSweep` primero alcanza wheel travel con rack cero y después mueve
  rack manteniendo `[zFL,zFR]`. El dato rackZeroKinematicResult conserva esa
  referencia; no es el primer sample solicitado.
- `solveBumpSweep` sólo prescribe el inboard estático. La extensión acepta
  **únicamente referenceRackTravel_m=0** para BUMP/ROLL: rechaza otra referencia,
  no modifica ni atribuye capacidades nuevas al solver histórico.
- Ackermann exige `rearAxleX_m` finito explícito del seed steering, contactos
  y headings reales. No basta un wheelbase conceptual ni los tie rods. El error
  canónico es actualOuter−idealOuter wrapped; inner/outer provienen del steering
  inducido, no del signo de q. Straight/ICR infinito/turn ambiguo son gaps,
  no Ackermann cero, porcentaje ni HARD PASS.
- ROLL nativo puede reconstruirse sobre las mismas geometrías con rack centrado.
  Sweeps independientes no certifican un grid simultáneo roll–bump–rack.

El pipeline reutiliza builders, mapa de simetría y normalización,
wrappers de evidencia/assessment de eje y el único boundedDirectSearch.
La extensión privada de bindings admite explícitamente dos roles adicionales;
las APIs públicas v0.12/v0.13 conservan su alcance y schema. No hay dependencias
de solvers/modelos históricos hacia synthesis ni nuevas ecuaciones de dirección.

## Alcance y decisiones de referencia

FRONT FL/FR, dos seeds explícitos y steering seed nativo coherente. Hasta XYZ
de los cuatro pivotes UCA/LCA y dos endpoints tie rod por lado, si se declaran
FREE/RANGE con límites finitos. El número real de DOFs procede de variables
autorizadas, frozen y vínculos seleccionados; no se afirman doce DOFs móviles.
Cambiar un inner modifica diseño/orientación/separación de rack entre candidatos;
su movimiento sigue siendo una traslación compartida durante cada sweep.
Montaje impuesto se expresa con FIXED/boxes nominales. La ausencia de restricciones
de mounting no significa collision-free. Límites de rack deben declararse en el
plan, incluir cero y contener todos los samples; no son límites FS inventados.

No se cambian +X atrás/+Y derecha/+Z arriba, SI, headings, toe ni Ackermann.
Se permiten diseños asimétricos. Simetría geométrica seleccionada sobre Y=0
no implica igualdad de ángulos firmados ni copia de curvas.

OPEN DECISION: montaje, recorrido físico, geometrías, tolerancias, targets,
escalas y prioridades del vehículo real; rack rotativo/compliance, columna/pinion,
continuidad global certificada y grid simultáneo de carretera/dirección.
Los valores del futuro benchmark son controles ilustrativos ASSUMED,
no recomendaciones de setup, validación CAD, normativa o fabricación.

## API y datos de la extensión

```matlab
space = fsd.synthesis.createSteeringDesignSpace(left,right,steeringSeed,spec,plan,links);
u = fsd.synthesis.normalizeSteeringVariables(space,space.initial_m);
x = fsd.synthesis.denormalizeSteeringVariables(space,u);
[steering,changes,diagnostics] = fsd.synthesis.buildSteeringCandidate(space,x);
evaluation = fsd.synthesis.evaluateSteeringCandidate(space,u,1);
result = fsd.synthesis.runSteeringInverseSearch(space,options);
fsd.synthesis.validateSteeringSynthesisResult(result);
comparison = fsd.synthesis.compareSteeringSynthesisCandidates(result,[1;2]);
figures = fsd.synthesis.plotSteeringSynthesisResult(result);
```

Plan explícito, en SI:

```matlab
plan.leftBump = struct('travel_m',[-.01;0;.01]);
plan.rightBump = struct('travel_m',[-.01;0;.01]);
plan.referenceRackTravel_m = 0;
plan.rack = struct('travel_m',[-.006;-.003;0;.003;.006], ...
    'wheelTravel_m',[0,0],'travelLimits_m',[-.01,.01], ...
    'solverOptions',struct());
% plan.roll opcional: contrato v0.13, rack centrado.
```

Las dimensiones anteriores son ejemplos de contrato, no límites físicos FS.
Grid finito estrictamente monótono o scalar; órdenes descendentes se conservan.
Límites finitos cerrados declarados que contienen cero y el grid completo.
El plan no rellena samples para satisfacer un target ni altera sus condiciones.
Referencia no cero, campos de grid multidimensional o condiciones incompatibles
se rechazan antes de buscar. Falta de rearAxleX/steering seed válido es un
prerrequisito de definición fallido, no un candidato HARD PASS.

Space/Evaluation/Result son structs schema0.14.0, con seeds por valor,
spec original única, planes/opciones canónicos, bindings físicos, mapa independiente
y vínculos seleccionados. Se conserva AxleGeometry y SteeringSystemGeometry nativos,
sin nuevos modelos físicos. El builder publica el mecanismo completo sólo si
ambos corners y rack son válidos. Cambios de coordenadas DERIVED y diagnósticos
con longitudes tie rod/separación/eje de rack seed y candidato registran efectos
físicos; ningún link se ajusta para hacer converger un solve.

## Métricas, calidad y selección

BUMP: CAMBER, TOE, BUMP_STEER, CASTER, KPI por corner. RACK: TOE,
ROAD_WHEEL_ANGLE, SCRUB_RADIUS, MECHANICAL_TRAIL por corner y
ACKERMANN_ANGLE_ERROR FRONT. ROLL mantiene las siete métricas v0.13.
No ratio arbitrario izquierda/derecha: pueden declararse ambos headings y el
error Ackermann nativo. No nuevos aliases, anti geometry, force steering,
pinion ratio ni actuation/equilibrium adapters inversos.

Toda geometría válida exige BUMP FL, BUMP FR y RACK bilateral nuevos, más ROLL
si fue solicitado. Aun si una fuente falla se intentan las independientes.
Fuentes múltiples con distintos IDs de una misma familia son aliases de la misma
evidencia; IDs no pueden cruzar corner/familia. Nunca BUMP seed con rack nuevo.

El guard de Jacobiano v0.12 deriva de las mismas cinco longitudes. En cada pose
RACK su quinta fila usa **tieRodInboardCurrent_m**; su L_i0 y referencia estática
pertenecen al mecanismo reconstruido. También se comprueba rackZeroKinematicResult
a wheel travel prescrito. Convergencia y conditioning/orientación local de ambos
lados son necesarios; no se certifican pasos internos no publicados ni unicidad.
No cambia el threshold sqrt(eps(double)) ni las tolerancias nativas.

Un único DesignCandidate y evaluateDesignCandidate v0.11 preservan HARD/SOFT,
knots, gaps y dominios. Violación HARD demostrada tiene prioridad, incluso con
otra evidencia parcial. Sin cobertura HARD no hay PASS completo. Sin cobertura
SOFT no hay score completo. El guard local permanece separado del assessment:
un PASS muestreado del adaptador no elimina una fuente cinemática no fiable.
Score exclusivamente RMS ponderado normalizado opt-in, escalas/pesos explícitos.
No penalización finita para fallo ni importancia igual automática.

La búsqueda es boundedDirectSearch v0.12: presupuesto único, polling/seeds/steps,
cache exacta por coordenadas SI decodificadas y conservación de todos los intentos.
Cache local a un contexto inmutable; no reutilización entre specs, referencias
traseras, planes, opciones o seeds distintos. Un score NaN no selecciona ganador.
Elegibilidad es sampled/local, nunca certificación global ni CAD.

## Provenance, fallos y validación

Identidad física nativa liga ambos corners y rack/referencia trasera. Snapshot
numérico separado liga seeds/frame/spec/variables/mapping/links/source aliases,
referencia rack cero, grids/opciones BUMP/ROLL/RACK, wheel travel y travel limits.
Cada wrapper liga contexto/evaluationId/modelIdentity al sweep nativo original.
No basta modificar snapshots superficiales para acreditar otra ejecución.

Allowlist cerrada por etapa: los errores geométricos históricos más tie rod
coincidente, upright pickup coincidente/degenerado y rack degenerado. No catch
universal; errores de programación/invariantes/toolbox se propagan. Fallos de
cierre se conservan como payloads nativos NO_CONVERGENCE/NOT_ATTEMPTED. Análisis
fallido conserva sweep/calidad, pero no fuentes falsas. Builder fallido conserva
vector/diagnóstico sin modelo ni identidad fabricados y consume cero sweeps.

Contadores distinguen candidatos/attempts/cache, BUMP L/R, RACK bilateral,
ROLL y corner closures internos de ROLL. Sweeps no son iteraciones fsolve.
Validators reconstruyen espacio, builder, evidencia, calidad, analysis,
assessment y replay del controller **sin solves**. MAT completo se revalida tras
load; identidades no son firmas criptográficas ni garantizan autenticidad externa.

Reporting consume esos datos: trace, diagnósticos, cambios de variables,
curvas nativas por lado, Ackermann y tradeoffs; muestras faltantes permanecen NaN.
Vista conjunta 3D mediante plotSteeringSystem sobre el sample convergido existente
más cercano a rack cero, identificado por q/evaluationId. No fabrica un estado
neutral si cero no fue solicitado y no dibuja una pose no convergida. Su UserData
conserva evaluation/sampleIndex; las vistas de corners siguen nominales.
Legends fuera del área de datos, tema oscuro local antes de hijos y claro explícito.
Single/no eligible/partial targets no crean comparación ni ganador ficticio.
Engineering change → Unit test → Known case → Validation → Merge (merge no autorizado).
Base MATLAB para controlador/reporting; Optimization Toolbox/fsolve para física.

## Proyección auxiliar de targets — V14-F-01

La especificación conjunta recibida se valida primero mediante la fábrica y
validator públicos v0.11. Para reutilizar los bindings del eje se construye
una **proyección auxiliar**, que conserva parámetros, restricciones y targets
BUMP/ROLL, pero omite temporalmente RACK. Esta proyección no es el problema
completo ni la especificación usada por el assessment final.

Si no queda ningún target SOFT en la proyección, únicamente su `compositeScore`
se pone a false: no hay score auxiliar calculable. Si queda algún SOFT,
se conserva la opción original. No se cambian targets, pesos, escalas,
tolerancias, bindings ni HARD. Una especificación pública sin SOFT y con score
activado sigue siendo inválida; se rechaza antes de proyectar.

El espacio publicado conserva la especificación original completa por valor,
incluidos identidad, orden y score opt-in. Snapshot, candidate y assessment
conjunto usan esa especificación, nunca la proyección. Se admiten cuatro SOFT
RACK, dos SOFT Ackermann únicamente y BUMP HARD + RACK SOFT sin SOFT BUMP/ROLL.
Los dos BUMP siguen generándose como evidencia/guard del pipeline; no se
convierten en objetivos artificiales. La política de elegibilidad no cambia:
HARD fallido/indeterminado, evidencia no fiable o cobertura incompleta no
permiten selección por score. Un assessment puede tener score SOFT finito
mientras el record no es elegible y guarda score NaN por HARD.

Straight-ahead Ackermann sigue indisponible. Score sólo utiliza todos los
SOFT declarados y su cobertura completa; nunca cero por ausencia de targets.
La corrección no cambia ecuaciones, solver, search, validadores o reporting.
V14-OBS-01 LOW: persiste el solapamiento título/exponente automático de los
gráficos Ackermann; fuera del alcance de F-01, sin edición del plot histórico.
