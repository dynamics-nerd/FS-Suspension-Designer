# v0.15 — Actuation Geometry & Motion Ratio Synthesis

## Inspección y arquitectura implementada

MATLAB R2025b. Modelos nativos inspeccionados: ActuationGeometry v0.7,
create/validateActuationGeometry, solveActuationSweep y su continuation;
analyzeActuationSweep; SpringDamperModel v0.8, analyzeSpringDamperSweep y
política de derivadas F01-1; targets/assessment v0.11 y boundedDirectSearch.
No segunda física de actuación ni segundo optimizador.

Modo obligatorio: DoubleWishboneGeometry seed **inmutable**, una actuación
PUSHROD/PULLROD y un SpringDamperModel opcional compatible. Geometría → BUMP
nativo nuevo → actuación circle/sphere nativa → análisis geométrico y mecánico
algebraico → assessment completo original → controlador v0.12. Todos los
corners FL/FR/RL/RR son admisibles. DIRECT ACTING no existe en la fábrica
histórica y queda explícitamente fuera. No síntesis simultánea de eje.

La arquitectura elegida es dato del problema, no una variable continua ni
una inferencia de fuerza axial. PUSHROD/PULLROD comparten el cierre histórico;
los benchmarks deben usar geometrías distintas, no sólo etiquetas distintas.

## Coordenadas y grados de libertad

Se conserva +X atrás/+Y derecha/+Z arriba, bump positivo, SI m/rad/N/N/m.
Los cuatro roles físicos existentes son ACTUATION_ROD_SUSPENSION,
ACTUATION_ROD_ROCKER, DAMPER_ROCKER y DAMPER_CHASSIS. Se añade el identificador
de diseño ROCKER_AXIS_POINT para el punto canónico de la línea del eje:
**no es un bearing, bracket ni punto de packaging**.

Scopes nominales `<CORNER>_<ROLE>`, bindings HARDPOINT_X/Y/Z, restricciones
HARDPOINT_FIXED y AXIS_ALIGNED_BOX reutilizados. La lista de diez hardpoints
obligatorios de DoubleWishboneGeometry no cambia. Los anclajes de actuación
permanecen en su modelo separado; no se insertan en la suspensión seed.

Los anclajes se almacenan en coordenadas globales de referencia theta=0,
como el modelo nativo. En cada candidato cambian radios/shape y longitudes
nominales si se autorizan; durante el sweep ambos puntos del rocker se
transforman por la **misma rotación rígida** sobre su eje. No se requieren
otros frames ni un rocker local ficticio.

La dirección orientada u del eje se conserva. Su punto canónico P satisface
u·P=0: sólo tiene dos DOFs. Se elimina la componente k con mayor abs(u_k),
primer índice en empates. Las otras dos XYZ pueden declararse; la dependiente
se reconstruye como P_k=-sum(i≠k,u_i*P_i)/u_k. Un FREE/RANGE móvil sobre k
se rechaza; un intervalo congelado no crea un DOF. La canonicalización nativa
(proyección y redondeo14 decimales) no se altera; coordenadas solicitadas y
logradas/cambios derivados deben conservarse. FIXED sobre una componente
dependiente también prohíbe una mutación indirecta que pudiera cambiarla.

UBJ/LBJ/upright/wheel axis/WC/contact/tie rod/trapecios/frame/provenance de la
suspensión son bit-idénticos al seed. Su síntesis conjunta puede componerse
externamente con APIs existentes, pero no forma parte de v0.15.

## Extensiones aditivas mínimas a los contratos

Los scopes de diseño admiten los cinco roles anteriores sin cambiar los roles
obligatorios de suspensión. DesignCandidate puede registrar `actuations`,
una cell vector de modelos nominales nativos. Cuando está ausente/vacío, la
definición e identidad históricas mantienen exactamente su forma previa.
Cuando existe, identidad y association map ligan geometría/actuación y fuentes
ACTUATION/MECHANICAL. Así puede comprobarse un box nominal antes de resolver,
sin fabricar una fuente física ni perder un HARD demostrado.

El catálogo añade ROCKER_ANGLE (ACTUATION/WHEEL_TRAVEL/CORNER/rad): ángulo
unwrapped nativo, mano derecha sobre u, cero en referencia nominal. No nueva
ecuación. Sus valores no requieren MR; convergencia/conditioning sí. Las 23
métricas y sus gates anteriores conservan su semántica.

## Parámetros, constraints y mecánica

Todos los FREE/RANGE geométricos requieren bounds finitos, seed dentro y
binding inequívoco; FIXED/HARDPOINT_FIXED HARD prohíbe movimiento aun con
tolerancia de comparación no nula. Duplicados rechazados. Bounds congelados
tienen u=0, siguiendo coordinateCore v0.12. No recortar geometría para pasar
boxes: se evalúa el modelo nominal reconstruido. No CAD ni colisiones.

Spring rate, free length, preload, damping law y límites proporcionados son
inputs del seed mecánico. Se reconstruye su asociación a cada actuación nueva
mediante la fábrica v0.8, manteniendo esos inputs físicos. FIXED/RANGE de
SPRING_RATE/PRELOAD se comparan como restricciones sobre valores conocidos;
no se optimizan. FREE mecánico no soportado se rechaza explícitamente.

Referencias distintas: longitud rod, longitud damper nominal, separación de
asientos, compresión de muelle, compresión damper y theta. Se reutiliza:
`c=Ldamper,0-Ldamper`, `MR=dc/dz`, `Fs=k*max(preload+c,0)` y
`Kw=k*MR^2+Fs*dMR/dz` sólo en su régimen de validez nativo. No clamping de MR
negativo o Kw negativo, ni sustitución por rigidez elástica cuando la curvatura
no es fiable. F01-1, engagement/unseated/bind/limits permanecen intactos.
La velocidad del plan se declara explícitamente en m/s (cero = reposo
prescrito), no se infiere del orden del sweep. No nueva hidráulica.

## API pública y datos

create/validateActuationDesignSpace, normalize/denormalizeActuationVariables,
buildActuationCandidate, evaluateActuationCandidate, runActuationInverseSearch,
validateActuationSynthesisEvaluation/Result, compareActuationSynthesisCandidates,
plotActuationSynthesisResult, bajo fsd.synthesis. Structs consumidores0.15/MAT.
Build acepta coordenadas SI; evaluate/search usan u en [0,1] del core existente.

Firma del espacio: suspensionSeed, actuationSeed, springDamperSeed (o []),
specification completa y plan. Plan explícito: travel_m, solverOptions BUMP
canónicas y wheelVelocity_m_per_s para mecánica. No opciones inventadas para
el cierre analítico del rocker. No rellenar grids para satisfacer targets.

Soporte: BUMP histórico de la esquina fija; ACTUATION DAMPER_COMPRESSION,
MOTION_RATIO, INSTALLATION_RATIO, ROCKER_ANGLE; MECHANICAL las seis métricas
históricas correspondientes. Fuente mecánica exige seed compatible. Fuente
locked/otro corner/familia no reconstructible se rechaza antes de buscar.
La especificación original no se proyecta ni se sustituye: ACT-only,
MECHANICAL-only, HARD+SOFT mixtos y HARD-only sin score conservan todos los
objetivos. Pesos/escalas/tolerancias no se inventan.

## Provenance, calidad, fallo y selección

Snapshot antes de solves: seed suspension/frame, actuación/arquitectura,
mecánica completa, especificación, variables/bounds, plan/opciones/velocidades
y aliases. Identidades físicas y contexto numérico son dominios separados.
Cada evidencia liga snapshot/evaluationId/modelo y payload nativo. Caché local
a un problema inmutable, por coordenadas SI exactas; no caché entre specs.

Contadores separados: attempts/unique/cache/builders; BUMP sweeps; actuación
sweeps y cierres analíticos reales; análisis mecánicos algebraicos. Builder
fallido no publica modelo ni invoca física. Violación geométrica HARD demostrada
puede abortar antes de física; el assessment conserva targets NOT_EVALUATED,
sin fuentes ficticias. Errores recuperables deben tener allowlist cerrada por
etapa; errores desconocidos se relanzan. No score penalizado o cero artificial.

Guards: cierre BUMP local v0.12 y convergencia/conditioning nativos de actuación.
Readiness/gaps/gates de cada métrica, incluyendo curvatura para Kw, deciden
disponibilidad. HARD demostrado tiene prioridad; incompleto no es PASS. Sólo
elegibles con score SOFT completo participan en selección; no óptimo global.

Validators reconstruyen bindings/builders/modelos, native analyses, calidad,
assessment y replay exacto del controlador **sin nuevos solves**. Tiempos no
son identidad ni certificado histórico. MAT se revalida tras load.
Los validadores físicos nativos reconstruyen raíces algebraicas de branch para
verificar estados almacenados; no se llama al solver forward ni a fsolve/fzero.
Cache exacta por solicitud SI, no por geometría redondeada: dos solicitudes
pueden canonicalizar al mismo eje14dp y causar evaluación adicional segura.

## Validación y límites

Resultados de tests, benchmark cinemático/mecánico, ejemplos, Analyzer/DAG,
profiler, PNG dark/light y mediciones: [informe verificable](v0.15-validation.md).
Los datos de benchmark son ASSUMED, con referencias y tolerancias de software
explícitas; no setups FS recomendados. Reporting no conecta gaps ni dibuja un
candidato fallido como seleccionado. Leyendas fuera de datos; exponentes locales
de figuras nuevas configurados para evitar solapamientos, sin cambiar plots
históricos ni preferencias globales.
Exportar con `exportgraphics(f,file,'Padding','figure')` conserva el lienzo
frente al tight-crop variable de ejes/diagnósticos. La línea gráfica del eje se
sitúa cerca del rocker (también rear); el punto canónico no se dibuja como bearing.

OPEN DECISIONS: geometrías/targets/rates/preload/tolerancias físicos del coche,
precisión por convergencia de malla y validación experimental, ramas continuas,
compliance, fuerza/buckling/resistencia del rod/rocker, bearings y packaging/CAD.
No fabricación, normativa, dinámica hidráulica, Adams, App Designer o v0.16.
