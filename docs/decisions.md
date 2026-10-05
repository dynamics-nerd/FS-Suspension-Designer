# Registro de decisiones

## Cerradas en v0.1

- **CS-001:** origen en el punto medio entre los contact patches delanteros sobre el suelo nominal.
- **CS-002:** `AbsTol = 1e-9 m`, `RelTol = 1e-9`, solo para software.
- **UN-001:** API de entrada con unidad explícita `m`/`mm`; núcleo siempre SI.
- **DM-001:** API funcional documentada en `data-model.md`, sin clases ni índices públicos.
- **DM-002:** MAT es el formato canónico de persistencia de V1.
- **DM-003:** procedencia almacenada por coordenada X/Y/Z.
- **NM-003:** wheel axis unitario, interior→exterior.

## Abiertas

- **OPEN DECISION NM-001:** nomenclatura de endpoints de actuación.
- **OPEN DECISION NM-002:** representación del eje de pivot del rocker.

Estas decisiones no bloquean v0.1 y no deben cerrarse antes de diseñar actuación.
