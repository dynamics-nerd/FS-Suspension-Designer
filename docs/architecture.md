# Arquitectura

## Objetivo y límite actual

FS Suspension Designer pretende conducir un flujo desde requisitos del vehículo hasta geometría, análisis, selección y validación externa. **v0.3 — Single-Corner Kinematic Analysis** interpreta los estados ya resueltos por v0.2 mediante métricas de una esquina. Rules, optimización, dinámica, modelos de eje completo y UI siguen sin implementación funcional.

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
| `geometry` | Primitivas y operaciones geométricas estáticas. |
| `kinematics` | Solver de bump, continuation y pose física del upright; no contiene reglas ni interpreta toe/caster/KPI. |
| `analysis` | Camber, toe, bump steer, caster, KPI y curvas derivadas de estados resueltos. |
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

## Integridad geometry/result

`fsd.model.geometryIdentity` genera una representación canónica versionada con todos los inputs geométricos consumidos por el solver: schema de geometría, `cornerId`, IDs de hardpoints en orden canónico, coordenadas XYZ y wheel axis estático. No incluye display names ni procedencia porque no alteran el mecanismo.

La identidad completa viaja en `KinematicResult`, `BumpSweepResult` y sus análisis derivados. Se compara con igualdad exacta sobre datos canónicos; no es un hash y, por tanto, no introduce colisiones ni dependencias externas. Dos structs de geometría con diferente orden interno pero los mismos IDs y datos físicos producen la misma identidad.

La identidad declara contra qué geometría debe ser coherente el payload; no demuestra criptográficamente qué llamada lo creó. Para impedir una identity sustituida sobre una pose incompatible, el validador reconstruye desde ella las cinco longitudes UCA/LCA/tie rod y comprueba el estado actual, además de Wheel Center travel y wheel axis transformado.

Los validadores `fsd.kinematics.validateSuspensionState`, `validateKinematicResult` y `validateBumpSweepResult` son propietarios del contrato del solver. `analysis` valida primero ese contrato y después exige identidad exacta con la geometría recibida. Un mismatch termina con `fsd:analysis:GeometryMismatch`, antes de calcular métricas.

## Flujo de datos

La frontera de entrada convierte unidades y nombres externos a un modelo canónico, conserva procedencia (`KNOWN`/`ASSUMED`) y valida estructura. El núcleo opera únicamente en coordenadas y unidades internas. Los resultados son datos explícitos, no estado oculto. La UI, los informes y los exportadores convierten esos datos a sus representaciones finales.

Un cálculo no debe depender de handles gráficos, componentes App Designer, variables del base workspace ni archivos implícitos. El flujo v0.3 es:

```text
DoubleWishboneGeometry
    -> fsd.kinematics.solveBumpSweep
    -> BumpSweepResult (estados físicos)
    -> fsd.analysis.analyzeBumpSweep
    -> BumpSweepAnalysis (métricas derivadas)
    -> plot/report/UI (conversión de presentación)
```

`analysis` no modifica estados, no repite el solve y no interpola puntos fallidos.

## Integración futura con Adams Car

Adams Car será una herramienta de validación de mayor fidelidad, no la definición interna del modelo. Un adaptador futuro mapeará IDs y unidades canónicos a su formato. El exportador no resolverá cinemática ni modificará la geometría para hacerla aceptable; cualquier transformación necesaria será explícita, probada y trazable. La comparación de resultados pertenecerá a un flujo de validación separado.

## Referencia de implementación MATLAB

- [MathWorks — Files and Folders That MATLAB Accesses](https://www.mathworks.com/help/matlab/matlab_env/files-and-folders-that-matlab-accesses.html), incluida la regla de añadir al path el padre de un namespace `+package`.
