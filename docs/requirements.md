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
