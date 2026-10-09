# Requisitos

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
