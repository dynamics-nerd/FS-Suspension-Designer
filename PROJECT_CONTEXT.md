# Contexto del proyecto

## Milestone actual

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
