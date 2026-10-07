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

## Cerradas en v0.4

- **AXL-001:** `AxleGeometry` compone dos structs de esquina y no introduce un
  plano X común. El wheel stagger es dato geométrico, no una referencia del
  análisis frontal.
- **FVI-001:** la restricción frontal de cada wishbone es perpendicular a la
  proyección YZ de la velocidad instantánea del ball joint, calculada como
  `cross(u, B-Paxis)`. La línea pasa por la proyección YZ del ball joint.
- **LIN-001:** puntos y líneas YZ se operan homogéneamente. Las intersecciones
  se clasifican `FINITE`, `INFINITE`, `COINCIDENT` o `DEGENERATE`; solo un
  punto finito publica coordenadas euclídeas.
- **LIN-002:** `conditioning=|sin(theta)|` para normales de línea unitarias;
  una intersección finita puede marcarse `isIllConditioned` sin reclasificarse
  arbitrariamente como infinita.
- **WHL-001:** radio geométrico desde `|CONTACT_PATCH-WHEEL_CENTER|`, sujeto a
  coherencia explícita con el círculo estático ideal y `Z=0`.
- **RC-001:** roll center es la intersección YZ de las líneas contacto ideal–FVIC;
  Y no se fuerza a cero.
- **RC-002:** height usa el nivel medio de contactos solo si ambos Z coinciden
  dentro de tolerancia numérica.
- **HEV-001:** heave simétrico es igual wheel travel por lado con chasis fijo.
- **FAIL-001:** un estado de sweep no convergido se construye como payload
  inválido nuevo; no hereda geometría dinámica de un análisis estático válido.

## Cerradas en v0.5

- **RACK-001:** el eje positivo del rack va de
  `FL_TIE_ROD_INBOARD` a `FR_TIE_ROD_INBOARD`; ambos joints reciben la misma
  traslación `q*u_rack`. El signo de `q` no define el sentido del giro.
- **STR-001:** continuation canónica en dos etapas: wheel travel con rack cero
  y rack travel manteniendo el wheel travel objetivo.
- **HDG-001:** el heading delantero se deriva del wheel axis proyectado; recto
  es `[-1,0,0]` y road-wheel angle positivo apunta a `+Y` para ambos lados.
- **ANG-001:** diferencias angulares mediante
  `atan2(sin(delta),cos(delta))`.
- **SCR-001:** `scrub=sideSign*(C_y-S_y)`; positivo es contacto más outboard.
- **TRL-001:** `mechanicalTrail=C_x-S_x`; positivo es intersección por delante
  con X global positivo hacia atrás.
- **ACK-001:** ICR por heading/contacto real sobre `X=rearAxleX`; no se usa la
  fórmula simétrica clásica como definición general.
- **ACK-002:** `ackermannAngleError=wrap(actualOuter-idealOuter)` y no se
  publica porcentaje Ackermann.
- **ACK-003:** el turn se deduce del steering inducido por rack, no del signo
  del rack; cerca de recto se publica un status y un ICR proyectivo infinito.
- **VAL-004:** la validez del análisis de steering es bilateral; un fallo
  unilateral invalida métricas de ambos lados pero conserva diagnostics por
  esquina.
- **PERF-001:** las APIs públicas validan y delegan en un core de análisis
  privado; un rack sweep validado no revalida cada estado durante analysis.
- **REG-001:** la compatibilidad rack cero se protege además con constantes
  golden obtenidas de v0.4.0 commit `6cf64c5c0a23d4c4deb396681a8dfdf2d2f4443d`.

## Abiertas

- **OPEN DECISION NM-001:** nomenclatura de endpoints de actuación.
- **OPEN DECISION NM-002:** representación del eje del rocker.

No han aparecido decisiones humanas nuevas que bloqueen v0.5.
