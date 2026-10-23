# Arquitectura

## Extensión v0.20 — actuación/mecánica

`ActuationView` es una subvista de `fsdui.View` con adaptadores puros de tablas,
planes, especificaciones y evidencia; no realiza cálculos de ingeniería. Se conserva
el shell App Designer y los flujos anteriores. Los tres comandos nuevos pasan por
Controller → workerRequest/perform → operationBody → APIs públicas `fsd.project`.
`configureActuationResources` construye modelos y revisa atómicamente; `ACTUATION_RUN`
prepara/ejecuta el motor nativo; `adoptActuationCandidate` adopta el par exacto.
SPECIFICATION/SYNTHESIS reutilizan la orquestación existente y la geometría fija0.15.

La recepción reconstruye las declaraciones con el mismo operationBody y sustituye
sólo registros ya validados en el punto de ejecución. Se mantiene RF-01/02/03, sin
solves durante recepción/visualización/adopción. Las protecciones del owner, epochs,
ledger y publicación MAT abarcan las acciones nuevas. La vista sólo muestra evidencia
actual o histórica con su compatibilidad; STALE no se recalcula ni se oculta.
Model/kinematics/analysis/synthesis siguen independientes de proyecto/UI; no nueva
arista de módulos ni un segundo mecanismo de revisiones, storage o worker.
[Contrato, datos, unidades y uso](guided-actuation-mechanics.md).

## Extensión v0.19 — Packaging

`fsd.packaging` consume modelos y estados nativos inmutables; no ejecuta
solvers ni búsquedas. Primitivas explícitas -> resolución de bindings ->
distancias exactas admitidas -> cobertura/diagnóstico -> resultado almacenado.
`fsd.project` incorpora el recurso opcional packaging y el motor PACKAGING
mediante preparación/compatibilidad/MAT canónicos. Cambiar sólo sus recursos
no altera las dependencias de BUMP. La vista `app/+fsdui/PackagingView` edita
borradores y muestra evidencia; las operaciones completas usan el worker ya
existente, sin paralelizar física histórica. No dependencia inversa desde los
solvers, reglas o síntesis. [Contrato](packaging-physical-feasibility.md).
Las fuentes usan PackagingSourceReference: proyección explícita sin escenarios
ni recursos Packaging, con igualdad exigida de preparación nativa. Evita copiar
recursivamente todo el proyecto padre; el EngineeringResult original se conserva
intacto en el ledger. resultCompatibility es la única clasificación canónica,
también para esas referencias verificadas, sin fingir una nueva ejecución.

La frontera de transporte/persistencia usa un grafo de valores reversible con
diccionario de texto e interning local de subárboles exactamente iguales, sin
tocar datos numéricos. El MAT de Packaging guarda configuración y registros
en variables separadas del mismo archivo para acotar la serialización. No cambia
el proyecto lógico ni las revisiones; se conservan lector y escritor clásicos.
El Controller amplía sólo el transporte: ENCODING (conversión cooperativa)
-> EXECUTING (ProcessPool, ingeniería/archivos) -> DECODING (conversión cooperativa).
Los mismos IDs/epochs, guard de reentrada, cancelación y escritor único abarcan
las tres fases. La conversión cede callbacks cada256 visitas/nodos, con guard
de reentrada activo y cancelación comprobada; no inicia backgroundPool. Este
quantum es de planificación, no una tolerancia ni límite de capacidad. Ningún
solver se mueve a threads ni se altera el controlador histórico de síntesis.

Corrección F-02: el dueño conserva el historial completo. El request transfiere
sólo los registros requeridos como padres; SAVE/VALIDATE/COMPATIBILITY conservan
el input completo y devuelven sólo el valor, mientras LOAD/NEW/DEMO reemplazan.
La fusión canónica valida ambas entradas una vez, conserva sus registros exactos,
comprueba asociación/IDs y reconstruye configuración sin volver a validar el
ledger que acaba de validar. El epoch se comprueba también después de fusionar.
La clasificación singular y masiva comparten compatibilityCore. Las garantías
de datos simples son composicionales sobre campos cerrados; no se eliminan
validadores de entradas externas. Sólo recursos/conceptos y replay nativo de
síntesis se memoizan localmente por contenido completo, nunca snapshots enteros
ni flags por revisión. No caché global ni cambio de física.
`[result,project]=runEngineeringScenario(...)` permite ejecutar y añadir en una
misma operación: entrada e input ledger completos validados, resultado nuevo
validado, unión exacta de esos valores inmutables con IDs únicos y orden canónico.
El output único previo y `attachEngineeringResult` independiente siguen vigentes;
no se introduce un flag para omitir validadores. La UI usa esta composición en
BUMP, SYNTHESIS y PACKAGING, no cambia solvers ni el controlador de búsqueda.

## Extensión v0.18

Shell App Designer R2026b de texto generado por el editor -> vista dinámica
`app/+fsdui/View` -> Controller (sesión, snapshots, IDs/epochs, ownership) ->
adaptador value-only perform -> APIs públicas project/construction/analysis/
synthesis/geometry. Ningún módulo físico depende de app. Worker de procesos
opcional para tareas completas; búsqueda histórica secuencial e intacta.
Sólo un escritor MAT; publicación temporal condicionada a operación vigente.
Esquemas físicos y envelope nativo sin cambios; whitelist de software amplía0.18.
[Contrato y límites UI](guided-design-interface.md).

## Extensión v0.17

`construction` usa model/geometry, assessment nominal analysis y adapters puros
del builder synthesis. No duplica criterios geométricos ni ejecuta search/solves.
`project` aplica el gate físico v0.16 y prepara PARAMETRIC_SEED/PARAMETRIC_BUMP;
construcción/BUMP se ejecutan explícitamente. Los módulos físicos/controlador
no dependen de construction. Origin bindings bloquean recursos obsoletos sin
reescribir históricos. UI permanece ausente. [Contrato](concept-to-seed.md).

## Extensión v0.16

`fsd.project` es consumidor de model/geometry/kinematics/analysis/synthesis;
ninguno de esos módulos depende de project. ConceptParameter reutiliza el
DesignParameter nativo. Concept → Scenario → preparación sin forwards → ejecución
explícita por API histórica → EngineeringResult con contexto original → MAT.
No nueva física ni controlador. Los recursos son opcionales por corner, no
cuatro suspensiones ficticias. Readiness valida sólo la configuración consumida;
`validateEngineeringProject` valida además el ledger histórico, con replay nativo
sin nuevos solves. La ejecución reside exclusivamente en executeScenarioCore.
[Contrato](vehicle-concept-project-workflow.md) · [Evidencia](v0.16-validation.md).

## Extensión v0.15

Una suspensión fija + actuación nativa + modelo mecánico opcional + spec/plan
explícitos → builder con fábricas existentes → preflight nominal HARD → BUMP
nuevo → actuación nueva → análisis geométrico/mecánico → assessment original
completo → boundedDirectSearch inalterado. Los estados físicos proceden del
candidato; no de curvas del seed. Sin proyecciones auxiliares ACT/MECH.
`fsd.synthesis` orquesta; model/kinematics/analysis/geometry no dependen de él.
Validación, comparación y reporting consumen evidencia almacenada sin forward
solves. Extensiones aditivas: scopes de actuación, registro nominal opcional
`DesignCandidate.actuations` y métrica ROCKER_ANGLE; contratos sin registro
conservan la forma anterior. Física, algoritmo, límites UI/rules/export intactos.
[Contrato](actuation-geometry-synthesis.md) · [Validación](v0.15-validation.md).

## Extensión v0.14

Un FRONT steering seed y dos corners → mapa de eje con bindings tie rod
privados opt-in → builders canónicos → BUMP por lado/RACK bilateral/ROLL
centrado opcional → un candidato/assessment v0.11 → boundedDirectSearch v0.12.
No solvers/modelos históricos dependen de synthesis. Nuevo schema consumidor,
sin nueva clase/servicio/módulo físico. Normalización/FIXED/simetría/builders y
evidencia/assessment/replay de eje se comparten; defaults/APIs v0.12/v0.13
mantienen sus schemas y alcance. Un pequeño core gráfico compartido extrae el
plot de eje y sitúa sus leyendas fuera de datos; evaluator/validators/reporting
no resuelven mecanismos. [Contrato](steering-geometry-synthesis.md).

## Extensión v0.13

Síntesis de eje en `fsd.synthesis`: dos seeds → bindings/mapa de simetría →
builders v0.12 → BUMP por corner y ROLL nativo opcional → candidato/assessment
conjunto v0.11 → único boundedDirectSearch → records/reporting/MAT.
No se almacenan dos búsquedas independientes como si fueran una síntesis de eje.
Nuevos structs consumidores; model/geometry/kinematics/analysis históricos no
dependen de synthesis ni cambian. Plots llaman a geometry para dibujar ambos
modelos; dependencias synthesis→model/kinematics/analysis/geometry, acíclicas.
Builders, evaluación de targets, replay/validators y UI siguen separados.
ROLL recibe ángulos/heave/opciones explícitos, no otro modelo de vehículo.
[Contrato de eje](axle-level-synthesis.md). Las exclusiones de abajo son históricas.

## Extensión v0.12

`fsd.synthesis` orquesta espacio → builder → BUMP/analysis nuevos → evaluación
v0.11 → polling local → candidatos/history. Structs/MAT; controlador matemático
separado de la física. Consume model/kinematics/analysis; geometry sólo se usa
por los módulos históricos, no se duplican primitivas. No hay dependencias
de módulos anteriores hacia synthesis, ni ciclos. Evaluación/reporting/replay
no ejecutan solves. Rules/export/UI intactos; optimization queda reservado
para extensiones posteriores, sin otra implementación paralela.
Las correcciones V12-F-01/F-02/F-03 permanecen dentro de synthesis: snapshot
canónico y asociación de evidencia, política cerrada por etapa, conservación
de fallos y reporting single/no-candidate. Solvers históricos y contratos de
comparación v0.11 intactos. Validators reconstruyen opciones/relaciones/análisis
sin nuevos solves; errores desconocidos se propagan, no son viabilidad física.
[Contrato](inverse-suspension-synthesis.md). Las exclusiones siguientes son
históricas por milestone; el estado actual es v0.12.

## Extensión v0.11

DesignParameter/Target/Constraint/Specification/Candidate y catálogo en model;
adaptadores tipados/evaluador/validators/reporting en analysis. Definición sin
geometría ni solves. Cada fuente nativa se verifica upstream una vez por llamada;
el core privado compara datos prevalidos sin validators ni solvers en loops.
Model.validateDesignCandidate es estructural; analysis.validateDesignCandidate
reconstruye integridad nativa. Las identidades del assessment enlazan spec y
candidato, sin copiar análisis completos. No modifica geometrías ni leyes.
DAG existente intacto; ningún solver depende de la capa de diseño. No UI,
optimización, nuevos servicios ni dependencias. [Contrato](design-requirements-target-evaluation.md).

## Extensión v0.10

GlobalStaticSystem/VerticalTireModel en model; preparación, energía, solve,
validadores y plots en analysis. Structs MATLAB/MAT, sin clases/servicios nuevos.
Model sólo valida contratos de modelos; la validación upstream cinemática y
construcción de pp ocurre downstream en prepareGlobalStaticSystem.
Loop privado recibe inputs prevalidos, sin resolver geometría/rocker/steering.
Se reutilizan springLaw/mechanicalBounds v0.8, no otra ley de muelle.
DAG preservado: geometry→model; kinematics→geometry/model;
analysis→geometry/kinematics/model. Sin model→analysis ni kinematics→analysis.
UI/rules/export no participan; el neumático vertical tiene frontera de ley
sustituible sin cambiar gravedad/muelles. [Contrato](global-static-equilibrium.md).
Los límites de las secciones históricas siguientes corresponden a su milestone.

## Objetivo y límite actual

FS Suspension Designer pretende conducir desde requisitos hasta validación externa.
v0.17 añade construcción paramétrica al proyecto v0.16 y síntesis v0.12–v0.15.
Targets de prestaciones, rules, dinámica, CAD, Adams y UI permanecen fuera.
Los límites de secciones históricas se refieren a su versión, no al estado actual.

## Capas

v0.9 añade structs VehicleParameters/VehicleLoadCase en model, independientes
de hardpoints. analysis resuelve algebraicamente cargas y consume respuesta
v0.8 validada para búsqueda local sobre path. No añade otro paquete vehículo
duplicado, nuevas tecnologías ni dependencia kinematics→analysis.
Distribución de cargas nunca llama solvers; roots locales son interpolación
explícita, no nuevos cierres de suspensión/rocker.

Flujos: masa/dimensiones/CG → VehicleParameters → VehicleLoadCase →
StaticVehicleLoads (familia o distribución cerrada) → demanda reducida por
esquina, cuando hay información → CornerStaticEquilibrium sobre path v0.8.
UI/plots sólo consumen resultados. Cuatro roots no son pose de chasis.
Véase [contrato v0.9](vehicle-static-equilibrium.md).

v0.8 mantiene esa separación. `model` contiene `SpringDamperModel`, identidad
y conversiones mecánicas; `analysis` contiene leyes, límites y proyección.
No se añade lógica mecánica a `kinematics`, `ActuationGeometry` o la UI.
El nuevo flujo es `ActuationSweepResult + ActuationSweepAnalysis + modelo
-> analyzeSpringDamperSweep -> respuesta/plots`. La geometría explícita en
la firma permite reutilizar el validador upstream existente, sin duplicarla
en el modelo. Se valida el agregado una vez en la frontera; el loop privado
no revalida fuentes por sample ni llama a ningún solver.

Un `ActuationResult` de roll, steering o recorrido asimétrico se consume con
`analyzeSpringDamperState`: axial-only, sin derivadas en rueda inventadas.
La API de camino prescrito distingue explícitamente una ley ideal de una
solución de rocker; no crea un contrato cinemático falso. Véase
[especificación mecánica](spring-damper-wheel-rate.md).

1. **Presentación (`app`)**: futura interfaz App Designer. Traduce interacción humana a llamadas del núcleo y presenta resultados.
2. **Núcleo de ingeniería (`src/+fsd`)**: modelos, validación y algoritmos independientes de la UI.
3. **Adaptadores de entrada/salida (`fsd.export`, futuros importadores)**: convierten datos en las fronteras del sistema.
4. **Datos (`data`)**: datasets versionados, nunca lógica ejecutable.

Solo el directorio `src` debe añadirse al path. MATLAB resuelve los subpaquetes desde su padre, evitando contaminar el path con cada carpeta interna.

## Responsabilidades de módulos

| Módulo | Responsabilidad prevista |
|---|---|
| `model` | Contratos de datos, IDs, unidades, geometría e identidad canónica. |
| `geometry` | Primitivas 3D/2D, intersecciones y contacto circular ideal. |
| `kinematics` | Cierre no lineal de esquina; composición de heave y dirección por rack. |
| `analysis` | Métricas interpretativas de esquina/eje, roll center y dirección. |
| `model/geometry/kinematics/analysis` | Actuación opcional: contrato, primitivas rígidas, cierre y métricas, respectivamente. |
| `vehicle` | Composición de las cuatro esquinas y parámetros del vehículo. |
| `tire` | Contrato sustituible para modelos de neumático futuros. |
| `dynamics` | Dinámica del vehículo futura, consumiendo el contrato de neumático. |
| `packaging` | Envolventes y comprobaciones de interferencia; no resuelve cinemática. |
| `rules` | Evaluación de reglas sobre datos o resultados suministrados. |
| `optimization` | Orquestación futura de evaluaciones mediante APIs públicas. |
| `export` | Adaptación a formatos externos; no recalcula ingeniería. |

Las carpetas reservan límites, no prometen una implementación inmediata. Un módulo solo se llenará cuando exista un caso de uso aprobado.

## Dependencias

Dependencias permitidas en la primera evolución:

- `geometry → model`.
- `kinematics → geometry, model`.
- `analysis → model` y contratos públicos producidos por `geometry` o `kinematics`.
- `vehicle → model` y contratos públicos de los subsistemas que componga.
- `dynamics → vehicle, model` y la interfaz pública sustituible de `tire`.
- `packaging`, `rules` y `export` pueden consumir modelos o resultados ya calculados.
- `optimization` puede orquestar APIs públicas, sin acceder a detalles internos.
- `app →` APIs públicas del núcleo.

Dependencias prohibidas:

- cualquier módulo del núcleo → `app`;
- `kinematics ↔ rules` en cualquier dirección;
- `export → kinematics` para recalcular resultados;
- un modelo concreto de neumático incrustado en `dynamics`;
- cálculos de ingeniería dentro de callbacks, importadores o exportadores;
- ciclos entre módulos.

Cuando dos módulos necesiten intercambiar información, compartirán un contrato de datos simple en `model` en lugar de llamarse mutuamente.

v0.2 depende de Optimization Toolbox exclusivamente dentro de `kinematics`, mediante `fsolve`. `model` y `geometry` no dependen del toolbox. La cinemática no llama a `rules`, `app`, exporters ni módulos futuros.

Por compatibilidad, `KinematicResult.camber_rad` y `fsd.kinematics.camberFromWheelAxis` continúan disponibles. La fórmula canónica reside en `fsd.geometry.camberFromWheelAxis`; los wrappers de `kinematics` y `analysis` aplican sus contratos públicos y llaman a esa primitiva. No se añaden toe, caster ni KPI al solver.

La dirección queda acíclica: `analysis → kinematics` para validar resultados, mientras `analysis → geometry` y `kinematics → geometry` consumen primitivas compartidas. `kinematics` no llama a `analysis`.

v0.4 conserva esa dirección. `model` define `AxleGeometry` e identities;
`geometry` no consume resultados cinemáticos; `kinematics` compone las APIs de
esquina sin interpretar roll center; `analysis` consume los contratos ya
validados. No existe llamada `kinematics → analysis`. La primitiva de
`geometry` obtiene cada restricción frontal desde el eje de pivotes y la
velocidad instantánea 3D del ball joint; `analysis` combina después esas
líneas mediante geometría proyectiva YZ. Ninguna capa necesita un plano X de
referencia compartido.

v0.5 conserva exactamente la misma dirección de dependencias:

```text
model
geometry -> model
kinematics -> geometry, model
analysis -> kinematics, geometry, model
```

`model` define `SteeringSystemGeometry`; `geometry` contiene el wrapping
angular y la intersección eje de dirección–plano horizontal; `kinematics`
generaliza el cierre existente para recibir la posición prescrita del inner
tie-rod; `analysis` interpreta headings, scrub, trail y Ackermann. No existe
ninguna llamada `kinematics -> analysis`.

## Integridad geometry/result

`fsd.model.geometryIdentity` genera una representación canónica versionada con todos los inputs geométricos consumidos por el solver: schema de geometría, `cornerId`, IDs de hardpoints en orden canónico, coordenadas XYZ y wheel axis estático. No incluye display names ni procedencia porque no alteran el mecanismo.

La identidad completa viaja en `KinematicResult`, `BumpSweepResult` y sus análisis derivados. Se compara con igualdad exacta sobre datos canónicos; no es un hash y, por tanto, no introduce colisiones ni dependencias externas. Dos structs de geometría con diferente orden interno pero los mismos IDs y datos físicos producen la misma identidad.

La identidad declara contra qué geometría debe ser coherente el payload; no demuestra criptográficamente qué llamada lo creó. Para impedir una identity sustituida sobre una pose incompatible, el validador reconstruye desde ella las cinco longitudes UCA/LCA/tie rod y comprueba el estado actual, además de Wheel Center travel y wheel axis transformado.

Los validadores `fsd.kinematics.validateSuspensionState`, `validateKinematicResult` y `validateBumpSweepResult` son propietarios del contrato del solver. `analysis` valida primero ese contrato y después exige identidad exacta con la geometría recibida. Un mismatch termina con `fsd:analysis:GeometryMismatch`, antes de calcular métricas.

## Flujo de datos

La frontera de entrada convierte unidades y nombres externos a un modelo canónico, conserva procedencia (`KNOWN`/`ASSUMED`) y valida estructura. El núcleo opera únicamente en coordenadas y unidades internas. Los resultados son datos explícitos, no estado oculto. La UI, los informes y los exportadores convierten esos datos a sus representaciones finales.

Un cálculo no debe depender de handles gráficos, componentes App Designer, variables del base workspace ni archivos implícitos. El flujo de eje es:

```text
left/right DoubleWishboneGeometry -> AxleGeometry
    -> solveAxleHeaveSweep (dos BumpSweepResult con continuation)
    -> AxleHeaveSweepResult
    -> analyzeAxleHeaveSweep
    -> FVIC/contact/roll-center migration
    -> plot/report/UI
```

`analysis` no modifica estados, no repite el solve y no interpola puntos
fallidos. Un punto sin convergencia bilateral publica métricas de roll center
como `NaN` y conserva el status de la cinemática. Su payload se crea inválido
desde cero y no reutiliza datos dinámicos de un estado estático válido.

El flujo de dirección v0.5 es:

```text
FL/FR DoubleWishboneGeometry -> FRONT AxleGeometry
    -> SteeringSystemGeometry(rearAxleX)
    -> solveSteering / solveRackSweep
       stage 1: wheel travel con rack=0
       stage 2: rack travel a wheel travel constante
    -> SteeringAxleResult / RackSweepResult
    -> analyzeSteering / analyzeRackSweep
    -> headings, toe, scrub, trail y Ackermann
    -> plot/report/UI
```

El rack desplaza ambos inner joints con una traslación común y no rota. El
análisis bilateral solo es válido si convergen ambas esquinas. Un fallo no
publica ángulos ni magnitudes geométricas con apariencia válida.

Las APIs públicas `analyzeSteering` y `analyzeRackSweep` validan sus contratos
completos antes de analizar. Ambas delegan después en un core privado; el
sweep valida una sola vez el conjunto y no vuelve a validar individualmente
cada resultado durante el análisis. El core privado no es una API accesible
para saltarse integridad.

## Integración futura con Adams Car

Adams Car será una herramienta de validación de mayor fidelidad, no la definición interna del modelo. Un adaptador futuro mapeará IDs y unidades canónicos a su formato. El exportador no resolverá cinemática ni modificará la geometría para hacerla aceptable; cualquier transformación necesaria será explícita, probada y trazable. La comparación de resultados pertenecerá a un flujo de validación separado.

## Flujo de actuación v0.7

La jerarquía permanece acíclica:

```text
model
geometry -> model
kinematics -> geometry, model
analysis -> kinematics, geometry, model
```

`ActuationGeometry` es un contrato opcional por esquina y no modifica
`DoubleWishboneGeometry`. Las rotaciones rígidas alrededor de líneas 3D son
primitivas de `geometry`; `kinematics` transforma el attachment y resuelve el
cierre rod–rocker; `analysis` calcula derivadas, ranges y migraciones. No se ha
creado una capa paralela para PUSHROD/PULLROD ni un modelo full-vehicle.

```text
KinematicResult / SteeringCornerResult
    + ActuationGeometry
    -> solveActuation / solveActuationSweep
    -> ActuationResult / ActuationSweepResult
    -> analyzeActuationSweep
    -> MR, stroke, rocker range, plot/report/UI
```

El resultado fuente viaja íntegro en `ActuationResult`; esto permite validar
pose, identity y payload sin repetir el solve. Un sweep valida una vez el
`BumpSweepResult` agregado y llama a un core privado por sample. No existe
dependencia `kinematics -> analysis`.
`SteeringCornerResult` lleva la identity del sistema y se valida mediante un
único contrato público antes de entrar en actuación. El validador de actuación
reconstruye el cierre desde geometría y source; no confía en candidatos o
conditioning publicados. Tras el primer fallo de continuation, los estados
restantes se construyen como `NOT_ATTEMPTED` sin llamar al core geométrico.

## Flujo de body roll v0.6

La jerarquía de dependencias no cambia:

```text
model
geometry -> model
kinematics -> geometry, model
analysis -> kinematics, geometry, model
```

`geometry` define el frame de carretera, líneas normalizadas YZ y distancias
firmadas. `kinematics` compone dos solves de esquina y resuelve la incógnita
escalar de cierre. `analysis` interpreta el resultado mediante camber, FVIC,
roll center y track. En particular, el solver de roll no llama a `analysis`.

```text
AxleGeometry + [zL,zR]
    -> solveAxleTravel / solveAxleTravelSweep
    -> AxleTravelResult

AxleGeometry + (phi,h)
    -> continuation de heave
    -> continuation de roll + fzero sobre Delta
    -> AxleRollResult / AxleRollSweepResult
    -> analyzeAxleRoll / analyzeAxleRollSweep
    -> camber chassis/road, FVIC, RC y tracks
    -> plot/report/UI
```

Las APIs públicas validan una vez y delegan el cálculo repetido a cores
privados. No se introduce un modelo de vehículo completo. La integración con
steering reutiliza `[zL,zR]` como input existente, pero no afirma mantener el
cierre exacto de carretera después de que steering cambie los contactos.

`solveAxleTravel` valida axle, unidades, target y opciones antes de delegar en
el core privado `solveAxleTravelCore`. El root solve de body roll recibe ya el
axle y settings validados y llama directamente a ese core. Así cada evaluación
de `F(Delta)` evita repetir validadores públicos sin exponer una vía pública
para omitirlos ni duplicar `solveCornerPath`.

## Referencia de implementación MATLAB

- [MathWorks — Files and Folders That MATLAB Accesses](https://www.mathworks.com/help/matlab/matlab_env/files-and-folders-that-matlab-accesses.html), incluida la regla de añadir al path el padre de un namespace `+package`.
