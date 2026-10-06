# Registro de decisiones

## Cerradas en v0.1

- **CS-001:** origen entre contact patches delanteros sobre el suelo nominal.
- **CS-002:** `AbsTol=1e-9 m`, `RelTol=1e-9`, solo software.
- **UN-001:** frontera m/mm; núcleo SI.
- **DM-001:** API funcional con structs e IDs públicos.
- **DM-002:** persistencia canónica MAT.
- **DM-003:** procedencia por coordenada.
- **NM-003:** wheel axis unitario interior→exterior.

## Cerradas en v0.2

- **KIN-001:** tie rod/toe link genérico cierra el tercer grado de orientación del upright; no se impone toe/yaw artificial.
- **KIN-002:** pose parametrizada por `deltaX`, `deltaY` y rotation vector; `deltaZ=wheelTravel`.
- **KIN-003:** cinco constraints externos; la rigidez interna se garantiza por transformación rígida.
- **KIN-004:** `fsolve` de Optimization Toolbox con continuation máxima de 5 mm.
- **KIN-005:** failure result explícito con valores cinemáticos `NaN`.
- **CAM-001:** `camber=-atan2(a_z, sideSign*a_y)`, en radianes.

## Abiertas

- **OPEN DECISION NM-001:** nomenclatura de endpoints de actuación.
- **OPEN DECISION NM-002:** representación del eje del rocker.

No han aparecido decisiones humanas nuevas que bloqueen v0.2.
