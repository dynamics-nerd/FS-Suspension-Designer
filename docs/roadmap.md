# Roadmap

## v0.1 — Static Double Wishbone Geometry

Completada y conservada: construcción, validación, consulta, reflexión, geometría elemental, plot y MAT. El schema se amplía en v0.2 con tie rod porque la pose del upright no podía cerrarse físicamente con solo UBJ/LBJ.

## v0.2 — Bump Kinematics

Estado: **implementada**.

Incluye:

- tie rod rígido con inboard fijo;
- upright rígido no degenerado;
- wheel travel individual en m/mm;
- pose con translation + rotation vector;
- cinco constraints de cierre resueltos con `fsolve`;
- continuation desde el estado estático y entre targets de sweep;
- transformación rígida de Wheel Center, Contact Patch y wheel axis;
- camber absoluto con signo común FL/FR;
- manejo explícito de no convergencia;
- comparación 3D y curva Camber(WheelTravel);
- benchmark analítico y tests de constraints, simetría, continuidad y fallo.

No incluye toe como output, bump steer, steering rack, caster, KPI, scrub, trail, instant centers, roll center, roll/pitch/heave de vehículo, actuación, packaging, reglas, neumáticos, dinámica, optimización, Adams ni App Designer.

## Milestone siguiente

No está definida. Ningún trabajo posterior se inicia desde v0.2.

