# Registro de decisiones

## Cerradas para v0.9

- VEH-001: modelos standalone en model y análisis en analysis; sin paquete
  duplicado ni dependencia de cuatro geometrías para masas/cargas.
- VEH-002: gravity obligatoria, inventarios explícitos, unknown por coordenada,
  sin convertir una masa base sin piloto en masa suspendida.
- LOAD-001: familia SVD escalada; representante algebraico no es solución única.
  Medidas/CW/simetría explícita cierran el cuarto dato, con residual/no negatividad.
- LOAD-002: CW=(FR+RL)/(M*g); medidas inconsistentes no fuerzan complement=1-CW.
- EQ-001: interpolación declarada del path validado, sin solves ocultos;
  default UNIQUE_ONLY, selección por referencia sólo si solicitada explícitamente.
- EQ-002: Kw completo F-01, clasificación local/no global; igualdad de fuerzas
  en extremos no prueba plateau sin tangentes marginales o branch unseated.
- OPEN DECISION futura: error experimental, roots continuas con refinamiento
  explícito y Coupled Chassis Pose & Global Static Equilibrium. No implementados.

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

## Cerradas en v0.6

- **AXT-001:** recorrido de eje general usa `[left,right]`; heave histórico es
  el subconjunto `[z,z]` y conserva schema `0.4.0` mediante wrapper.
- **ROL-001:** `phi` es rotación de mano derecha alrededor de `+X`; `phi>0`
  produce carretera descendente hacia `+Y` en el frame del chasis.
- **ROL-002:** `h=(zLeft+zRight)/2`; la incógnita es Delta con
  `zLeft=h+Delta`, `zRight=h-Delta`.
- **ROL-003:** cierre escalar por contactos reales, root `fzero` bracketed y
  continuation canónica heave-first/roll-second.
- **ROL-004:** `abs(phi)<pi/2` preserva dirección left→right y normal +Z; no es
  un límite físico del vehículo.
- **ROAD-001:** road line YZ normalizada con normal +Z; se distinguen target
  orientation y línea resuelta desde contactos.
- **CAM-002:** road-relative camber aplica `Rx(+phi)` al wheel axis y después
  la ecuación histórica sin redefinir su signo.
- **RC-003:** `rollCenterHeight_m` conserva semántica v0.4;
  `rollCenterRoadHeight_m` es una métrica nueva de distancia firmada.
- **TRK-001:** wheel-center track usa diferencia Y del chasis; contact track
  proyecta sobre `dRoad`; migración referencia `h=0,phi=0`.
- **INT-001:** steering puede consumir los wheel travels de roll, pero no se
  afirma cierre exacto de carretera después de steering ni Ackermann en roll.
- **PERF-002:** análisis de sweep valida públicamente una vez y usa core privado.
- **ROL-005:** el bracket explora ambos sentidos independientemente, refina el
  límite válido por bisección y selecciona el intervalo válido adyacente más
  próximo al Delta previo; no realiza búsqueda global de raíces.
- **FAIL-002:** `ROOT_NOT_BRACKETED`, `KINEMATIC_NONCONVERGENCE` y
  `SCALAR_NO_CONVERGENCE` describen respectivamente falta de cambio de signo
  en dominio válido, dominio cinemático insuficiente y fallo tras bracket.
- **ANA-002:** los sweeps publican `kinematicStatus` y `analysisStatus`
  separados; un gap cinemático válido no invalida el contrato del análisis.
- **PERF-003:** `solveAxleTravelCore` es privado y asume axle, target SI y
  settings ya validados; las APIs públicas conservan validación completa.

## Cerradas en v0.8

- **SD-001:** COILOVER ideal, muelle lineal compresión-only y geometría de
  asientos derivada de longitud libre/preload; no se añade fuerza a actuación.
- **SD-002:** resistencia generalizada firmada como gradiente de energía;
  wheel rate total incluye `Fs*dMR/dz`. Negativo se conserva como diagnóstico.
- **SD-003:** estado individual axial-only; sweep usa MR de v0.7 validado.
  Geometría explícita adicional en la firma permite reutilizar su validador.
- **SD-004:** dMR/dz desde interpolante cuadrático de c(z), no de MR aproximado;
  stencil centrado/escalado y safeguards numéricos documentados. Gaps no se
  cruzan y datos no se reordenan. No se afirma orden dos en todo caso no uniforme.
- **SD-005:** damping lineal asimétrico y tabulado sin extrapolar; force
  magnitude no tiene que ser monótona, pero la disipación es no negativa.
- **SD-006:** UNKNOWN sin bounds; exceeded invalida respuesta constitutiva;
  transición de engagement y coil-bind boundary no tienen tangent bilateral.
- **SD-007:** benchmarks con camino prescrito explícito, nunca ActuationResult
  falsificado. Es una hipótesis ideal de test, no validación de rocker físico.
- **SD-008:** extrema completos o NaN ante samples no disponibles, sin esconder
  estados faltantes. Result validators reconstruyen payload, no sólo shape.

No se requiere nueva decisión física humana para este modelo ideal solicitado.
OPEN DECISION para una milestone futura: cualquier ley de bump stop/post-bind,
spring no lineal o damper con gas/hysteresis requiere especificación y aprobación;
no se elige ni implementa aquí. NM-001/NM-002 siguen resueltas y ARB-001 intacta.

## Abiertas al cerrar v0.7

No hay decisiones abiertas al cerrar v0.7.

## Cerradas en v0.7

- **NM-001 (resuelta 2026-10-07, v0.7):** el elemento genérico es `ACTUATION_ROD`; sus
  endpoints canónicos son `ACTUATION_ROD_SUSPENSION` y
  `ACTUATION_ROD_ROCKER`. PUSHROD/PULLROD comparte solver y solo diferencia la
  arquitectura/identity.
- **NM-002 (resuelta 2026-10-07, v0.7):** el rocker axis es una línea 3D
  `P+lambda*u`, con `P` canonicalizado como punto más próximo al origen y `u`
  unitario/orientado. El signo de `u` define el signo positivo de theta.
- **ACT-001:** el attachment puede pertenecer a UPRIGHT, UCA o LCA; upright
  reutiliza su pose exacta y los brazos rotan rígidamente sobre FWD→AFT.
- **ACT-002:** el closure rod–rocker es analítico círculo–esfera; no usa un
  solver iterativo ni búsqueda global.
- **ACT-003:** una llamada aislada elige la raíz equivalente más próxima a
  theta=0; un sweep elige la más próxima al theta unwrapped anterior.
- **ACT-004:** tangencia converge con conditioning cero y diagnóstico
  `TANGENT`; se clasifica con los coeficientes antes de `acos` y publica una
  sola raíz. No-intersection y underconstrained conservan statuses distintos.
- **ACT-005:** `orientationMode` es una ayuda de construcción y no forma parte
  de la identity física; el eje 3D canónico sí forma parte de ella.
- **ACT-006:** el validador reconstruye la rama cerrada y cada sweep encadena
  exactamente el ángulo anterior; tras un fallo no se ejecutan estados nuevos.
- **MR-001:** `damperMotionRatio=dCompression/dWheelTravel`; el installation
  ratio es su valor absoluto.
- **MR-002:** derivadas mediante interpolante cuadrático local sobre tres
  puntos, válido con spacing no uniforme; no se usa una curva `diff` desplazada.
- **MR-003:** las derivadas requieren recorrido estrictamente monótono y la
  referencia estática usa el target solicitado exactamente igual a cero.
- **ARB-001:** la futura estrategia de producto será `INTEGRATED`,
  `POST_DESIGN` o `DISABLED`. No se implementa ARB en v0.7.
