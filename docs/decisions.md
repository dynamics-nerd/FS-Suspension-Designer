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

## Cerradas en v0.3

- **TOE-001:** toe positivo es toe-in; `toe=atan2(-a_x, sideSign*a_y)` y se ignora `a_z`.
- **BST-001:** bump steer es toe absoluto menos toe estático de la geometría, incluso si el sweep no contiene cero.
- **AXIS-001:** steering axis dirigido y unitario LBJ→UBJ, sin imponer componente Z positiva.
- **CAS-001:** caster se obtiene en XZ; positivo cuando el extremo UBJ está hacia `+X`.
- **KPI-001:** `kingpinInclination` se obtiene en YZ; positivo hacia el centro y simétrico por lado.
- **ANA-001:** estados no convergidos se conservan sin interpolación, con métricas `NaN` y status original.
- **ID-001:** resultados cinemáticos vinculados mediante identidad canónica versionada, sin hash: schema, corner, IDs/XYZ canónicos y wheel axis.
- **VAL-001:** `kinematics` posee los validadores de `SuspensionState`, `KinematicResult` y `BumpSweepResult`; `analysis` añade la comprobación contra la geometría recibida.
- **VAL-002:** `converged` y `status` forman una invariante cerrada; no se admiten statuses libres.
- **ID-002:** la identidad es una declaración canónica, no provenance criptográfica; la coherencia se demuestra verificando pose, travel, wheel axis y cinco constraints externos.
- **VAL-003:** `diagnostics.attempted` distingue solve ejecutado de target no intentado sin inferirlo de los contadores de `fsolve`.
- **ARCH-001:** la fórmula única de camber reside en `geometry`; `kinematics` y `analysis` son wrappers sin dependencia circular.

## Abiertas

- **OPEN DECISION NM-001:** nomenclatura de endpoints de actuación.
- **OPEN DECISION NM-002:** representación del eje del rocker.

No han aparecido decisiones humanas nuevas que bloqueen v0.3.
