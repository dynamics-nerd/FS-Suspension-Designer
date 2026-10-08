# Requisitos

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
