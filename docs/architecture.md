# Arquitectura

## Objetivo y límite actual

FS Suspension Designer pretende conducir un flujo desde requisitos del vehículo hasta geometría, análisis, selección y validación externa. **v0.6** añade recorrido asimétrico de eje, cierre geométrico de body roll y análisis relativo a carretera sobre las capacidades de dirección v0.5. Rules, optimización, dinámica, vehículo completo y UI siguen sin implementación funcional.

## Capas

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
| `actuation` | Geometría y métricas de accionamiento futuras. |
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
- `actuation → geometry, model`.
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
