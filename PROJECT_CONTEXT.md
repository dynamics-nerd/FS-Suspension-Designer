# Contexto del proyecto

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
