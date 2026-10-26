# Contexto del proyecto

## Corrección focalizada V23-F-02 — 26 octubre 2026

El usuario comunica el cierre independiente de V23-F-01 y el nuevo MEDIUM
V23-F-02. Apply sin edición debe preservar exactamente todos los campos de los
planes ARB y las opciones/metadatos cargados, manteniendo revisión y resultados
CURRENT_EXECUTION. Las ediciones reales deben conservar la invalidación existente.
Corrección en ArbView validada por el desarrollador: 45/45 PASS, Analyzer 0/763,
MAT exactos y Desktop; reauditoría pendiente.
Sin cambios de física, worker, compatibilidad ni esquema MAT, sin gestión Git
ni v0.24. [Estado y evidencia](docs/v0.23-f02-validation.md).
Los apartados siguientes son checkpoints históricos.

## Corrección focalizada V23-F-01 — estado vigente

Auditoría independiente v0.23: CHANGES REQUIRED, un único MEDIUM en conversión
de target entero ARB_SIZING en ArbView. El usuario informa contrastes favorables
del núcleo ARB/global y de integridad; no se reabren. Corrección limitada a
presentación/Apply, tests y documentación, pendiente de reauditoría independiente.
Sin gestión Git ni v0.24. [Seguimiento](docs/v0.23-f01-validation.md).

## Desarrollo v0.23 —25 octubre2026 (contexto vigente)

El usuario confirma v0.22.0 publicada. Base comprobada:
`044aa1ea0c899f41146c015ee6e190b63d6829a7`; rama activa del usuario
`feature/v0.23-anti-roll-bar`, repositorio principal, sin worktree nuevo.
Gestión Git exclusiva del usuario. No v0.24. Los estados y prohibiciones de
apartados anteriores se conservan como historia, no como alcance vigente.

Alcance autorizado Anti-Roll Bar & Axle Coupling: recursos equivalentes y
coaxiales, referencias libres explícitas, accionamientos ROCKER/UPRIGHT/UCA/LCA,
energía/gradiente/Hessiano, dimensionamiento circular escalar, packaging
muestreado y GLOBAL_STATIC opcional por eje. Núcleo independiente de UI y de
complementos; no nuevos modelos estructurales, dinámica ni optimización conjunta.
Contratos: [anti-roll-bar](docs/anti-roll-bar.md). El registro central conserva
el estado de incrementos y los problemas encontrados. La validación de desarrollo
y la auditoría independiente siguen siendo actividades separadas.
Implementación y validación del desarrollador completas:385/385 seleccionados
PASS (58 nuevos/327 históricos),19 Desktop, Analyzer0/761, DAG27, inventario2144
con2086 IDs anteriores conservados. MAT auténticos0.19–0.22 exactos, worker real,
ejemplo y rendimiento documentados en [v0.23-validation](docs/v0.23-validation.md).
Auditoría independiente pendiente; sin gestión Git ni inicio de v0.24.

## Desarrollo v0.22 —24 octubre2026 (contexto histórico)

Base estable publicada v0.21.0, commit362e92e539e6941bd9d582966a934c25fe60d937.
Rama del usuario feature/v0.22-tire-models-foundation; gestión Git exclusiva del
usuario. Alcance autorizado Tire Models Foundation, incrementos A–E; no v0.23.
Contrato docs/tire-models-foundation.md; evidencia docs/v0.22-validation.md.
Implementación y validación del desarrollador completas:161/161 seleccionados
PASS (49 nuevos/112 históricos), Analyzer0/703, DAG26; inventario2067 con2018 IDs
anteriores conservados. Auditoría independiente pendiente; no suite completa.
Estado posterior: auditoría independiente CHANGES REQUIRED por V22-F-01/02/03,
todos MEDIUM. Correcciones acotadas validadas por el desarrollador:112/112 PASS
(19 nuevas/93 regresiones), Analyzer0/708, DAG26, inventario2086 sin perder IDs.
Reauditoría independiente pendiente. El informe
original se conserva y docs/v0.22-audit-corrections.md registra la reauditoría.
Geometry Only/Generic/Custom con biblioteca, revisiones/asignaciones, Dugoff
reducido estacionario explícito, carga/camber declarados y caracterización/UI.
GLOBAL_STATIC conserva física/ruta histórica y añade proyección vertical de
biblioteca; adherencia no invalida equilibrio que no la consume.
Alternativa C aprobada: núcleo independiente y adaptadores MathWorks opcionales.
Usuario instaló Extended Tire Features26.2.3; pruebas públicas sintéticas fuera
del repositorio identificaron diferencias entre Dugoff MathWorks y variante
nativa. No conversión silenciosa ni modelos de turismo como datos FS.
Sin TTC/identificación/MF propios ni expansión de prestaciones/targets/ARB.
Los apartados siguientes son históricos: sus estados de auditoría/publicación
no describen la base actualmente publicada y no cancelan la autorización0.22.

## Desarrollo v0.21 —23 octubre2026 (contexto histórico)

Implementación y validación del desarrollador completas:324/324 identidades
seleccionadas PASS (27 nuevas/297 históricas), Failed0/Incomplete0; inventario2014
con1987 IDs anteriores conservados, Analyzer0/674, DAG24. No suite completa2014.
MAT auténticos0.20(4 registros) y0.19(1) exactos; UI nueva3 +histórica3, worker real4.
Entrega output/v021-validation/guided-global-static.mat y docs/v0.21-validation.md.
Auditoría independiente pendiente; no implica aprobación de release/fabricación.

Base publicada v0.20.0, commit9685942, rama activa gestionada por el usuario
feature/v0.21-global-static-equilibrium. Repositorio principal, sin worktree.
Gestión Git exclusiva del usuario: no modificar referencias, índice, commits,
pushes, merges, tags ni releases. No iniciar0.22. Los apartados inferiores son
históricos; sus prohibiciones de iniciar0.21 no cancelan la autorización actual.

Alcance: preparar FL/FR/RL/RR explícitos e integrar GLOBAL_STATIC, reutilizando
el núcleo reducido0.10. SI y convenciones intactas. El adaptador genera los
cuatro paths de producción en reposo durante la ejecución solicitada; readiness,
recepción, compatibilidad y visualización no ejecutan nuevos solves.
Contrato: docs/guided-global-static.md; estado de pruebas: docs/v0.21-validation.md.
Mismas protecciones RF-01/02/03 y almacenamiento MAT0.19. Sin nueva física de
neumáticos de prestaciones, ARB, dinámica, Tilt o Adams. Auditoría independiente
reservada para otra conversación; validar localmente no equivale a aprobar release.

## Entrega local v0.20 —21 octubre2026

Implementación y validación del desarrollador completas:592/592 identidades únicas
seleccionadas PASS,33 nuevas +559 históricas, Failed0/Incomplete0. Analyzer0/662,
DAG24 acíclico;1954 IDs históricos conservados, inventario1987, no suite monolítica.
MAT auténtico0.19 exacto, proceso real/síntesis/adopción/MAT, UI y STALE verificados.
Código físico372 archivos sin cambios. Informe docs/v0.20-validation.md;
ejemplo revisable output/v020-validation/guided-actuation-mechanics.mat. Auditoría
independiente pendiente, ninguna aprobación de publicación o fabricación.

Base estable publicada v0.19.0 `58ee34baa942ee43e9e8748ab9fe50a5819b4329`.
Rama gestionada por el usuario `feature/v0.20-actuation-mechanics`; trabajo en el
repositorio principal, sin worktree separado. No modificar referencias Git,
commits, pushes, merges, tags ni releases. No v0.21. Se conservan cambios anteriores
y los seis tests de configuración. El usuario autoriza completar0.20 por incrementos
A/B/C/D y reserva auditoría independiente para otra conversación.

Alcance: operación guiada de los modelos0.7/0.8/0.15, actuación y coilover explícitos,
ACT/MECH, síntesis fija/comparación/adopción y MAT/worker. Sin nueva física ni rediseño
visual general. Contrato en docs/guided-actuation-mechanics.md, resultados reales en
docs/v0.20-validation.md. No confundir implementación con aprobación independiente.
Documentación continua obligatoria: contratos, arquitectura, datos, decisiones,
requisitos, tests, validación y roadmap afectados deben permitir una memoria técnica
sin depender del chat. No reconstruir como hechos motivaciones históricas desconocidas.

Roadmap provisional:0.21 cuatro esquinas/equilibrio,0.22 neumáticos,0.23 ARB,
0.24 performance/eventos reducidos,0.25 targets fundamentados; resto abierto.
Ingeniería antes de UI definitiva y Adams. Direct Acting pendiente, fuera de0.20.
docs/development-register.md centraliza estado/IDs/dependencias, separado de los
contratos y las evidencias. docs/original-requirements fue aportado por el usuario
y permanece sin editar. Los apartados siguientes son historia, no prohibiciones
nuevas que cancelen el alcance0.20 aprobado.

## Seguimiento RF-03 —21 octubre2026

Recepción vinculada a la operación inmutable del propietario, además de validar
canónicamente el contenido nativo. Implementación/validación local completas:
286/286 identidades únicas PASS,48 nuevas +238 existentes, sin faltantes/fallos/
incompletos; inventario1954, no suite completa repetida. Analyzer0/643, DAG24.
Las tres rutas largas y MAT exacto de nueve registros pasaron; limitaciones de
latencia conservadas, sin promesa de fluidez continua. Pendiente de reauditoría
independiente. Contrato/matriz/informe: docs/v0.19-rf03-operation-contract.md.
Evidencia nueva rf03-*, fuentes congeladas; no repetir ni sobrescribir las pruebas
anteriores. Sin cambios adicionales de física, commits, releases ni v0.20.

## Correcciones finales RF-01/RF-02 —21 octubre2026

Alcance exclusivo: claves de comparación char/string sin reescribir IDs y
validación obligatoria del protocolo de respuestas antes de aplicar APPEND/
REPLACE. Cuatro archivos app y una nueva clase de34 tests; núcleo fsd sin cambios.
Informe vigente: docs/v0.19-final-rf-corrections.md, evidencias work/v019-fixes/rf-*.
Validación local final:155/155 identidades seleccionadas PASS,34 nuevas y121
regresiones; las tres pruebas largas afectadas pasaron. Analyzer0/639, DAG24,
inventario1906 (no suite completa repetida). Núcleo/evidencias/refs intactos.
No atribuir la cobertura anterior1872 a una nueva suite completa tras RF.
Se mantienen las pausas/limitaciones de rendimiento aceptadas. Sin commits,
merges, tags, releases ni v0.20; pendiente de reauditoría focalizada independiente.

## Entrega local de correcciones de auditoría v0.19 — 20 octubre 2026

V19-F-01/V19-F-02 implementadas y verificadas localmente, pendientes de
reauditoría independiente.1872/1872 identidades únicas PASS en37 particiones,
18 ejemplos/siete benchmarks conservados, Analyzer0/638 y DAG24 acíclico.
Flujo gráfico completo real940,802s; MAT9/10 registros exactos, v0.18 real leído.
Principal1,938GiB privados/agregado4,128GiB en ese caso; no es RAM residente.
Inspección Desktop real: filtros/3D/muestras/candidatos/STALE/guardar/abrir,
rotación/zoom/maximización. No resultado de cierre manual final por presupuesto
de observación y después reserva de RAM; tests de ciclo de vida sí PASS.
Persisten huecos de callbacks de hasta45s en la fusión canónica y sobrecoste de
serialización; no prometer UI continuamente fluida ni capacidad arbitraria.
El cierre histórico de abajo no implica aprobación independiente. Evidencia
nueva en work/v019-fixes; informe de21 puntos e inventario52 rutas en
docs/v0.19-audit-corrections.md. Conservar el bundle previo sin sobrescribirlo.
Sin commits, merges, tags, releases ni v0.20. Pruebas pesadas en procesos
aislados, una a la vez, con presupuesto y vigilancia explícitos de memoria.

## Entrega histórica anterior a la auditoría (no cierre de las correcciones)

v0.19 Packaging & Physical Feasibility cerrada localmente, preparada para
auditoría independiente con limitaciones de escalabilidad explícitas. Base publicada
v0.18.0/main ce3ced0; rama feature/v0.19-packaging-feasibility. MATLAB R2026b.
Núcleo independiente fsd.packaging, recurso opcional project, tablas/visor
Packaging y consumo explícito nominal/BUMP, sin nuevos solves implícitos.
No cambiar física, controlador histórico, scores, convenciones o HARD/SOFT.
Contrato docs/packaging-physical-feasibility.md; estado real, fallos y tiempos
docs/v0.19-validation.md. No commits/merges/tags/releases ni v0.20 autorizados.
Conservar fuentes y548 evidencias históricas protegidas antes de los cambios.
Seguimiento de memoria: un SAVE de prueba alcanzó24GB privados y se detuvo sin
marcar PASS. Se añadió transporte reversible de strings, MAT nativo por registro
y fases puras ENCODING/DECODING en backgroundPool; ingeniería sólo ProcessPool.
50 casos nuevos distintos PASS; GUI completo1/1PASS(3001,6s), MAT anterior y nuevo
exactos;18 ejemplos/siete benchmarks conservados; Analyzer0/623,DAG24.
Intento completo congelado1824/1825:1795 históricos PASS y un antiguo fallo UI
corregido/revalidado después. No1845/1845 monolítico actual. Inspección real en
Desktop completada. Código MATLAB/XML624 coincide con copia validada.
El flujo asíncrono completo tardó1197,9s(worker470,9s); memoria privada muestreada
21,85GiB, pico residente9,57GiB. No es un producto ligero ni de latencia garantizada.
Inventario42 añadidos/28 modificados;677 fuentes/documentos;548 evidencias y362
archivos históricos de núcleo intactos. Entrega local output/v019-validation.

## Contexto histórico v0.18

v0.18 Guided Suspension Design Interface, rama
`feature/v0.18-guided-design-ui`, base estable correctiva v0.17.1 / main f14ed1e.
MATLAB R2026b; baseline aceptada1701/1701,17 ejemplos,Analyzer0.
Shell auténtico App Designer `.m`+`.xml`; controlador/vista `app/+fsdui`.
Proyectos, concepto,28 decisiones, DW/3D, BUMP, targets manuales HARD/SOFT,
síntesis corner/FRONT, comparación, adopción explícita y MAT nativo.
PCT sólo para operaciones completas asíncronas con snapshots/epochs; no parfor
en el controlador histórico. Núcleo físico/SI/+X atrás/+Y derecha/+Z arriba intactos.
Guía docs/guided-design-interface.md; ejecución real docs/v0.18-validation.md.
Implementación local completa, pendiente de auditoría independiente:1701 históricos
sin fallos en el intento completo;40 nuevos PASS en cierre separado, no1741/1741
monolítico.17 ejemplos/siete benchmarks,Analyzer0/580,DAG20 aristas sin ciclos.
No commits, merges, tags, releases ni v0.19. No modificar main ni referencias.

## Contexto histórico v0.17

v0.17 Concept-to-Seed & Parametric Suspension Geometry, rama existente
feature/v0.17-concept-to-seed, base local v0.16.0/main 746bdde.
Concepto -> decisiones -> geometrías nativas -> BUMP explícito -> síntesis
histórica -> proyecto/revisiones/MAT. Radio efectivo no inferido del descargado.
Contrato docs/concept-to-seed.md; evidencia real en docs/v0.17-validation.md.
No modificar main/commit/merge/tag/release/v0.18/App Designer ni física histórica.

## Propósito

Diseño Formula Student trazable, sin presentar supuestos como mediciones.

## Alcance

Familia rígida double wishbone, corner o FRONT simétrico/independiente.
No certificación CAD, prestaciones, fabricación ni normativa.

## Contexto

v0.16 cerrada con1564 tests/16 ejemplos/Analyzer0 de519 archivos. La revisión
posterior identificó como primer bloqueo la ausencia de seeds paramétricas.
