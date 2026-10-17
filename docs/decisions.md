# Registro de decisiones

## UI v0.18

- UI-010 (V18-F-01): conservar históricos en Analysis, marcar compatibilidad
  canónica junto a curvas y poses, y separar convergencia original de vigencia.
  Las revisiones identifican ejecuciones, no sustituyen resultCompatibility.
- UI-011 (V18-F-02): Extra JSON sólo admite ruleReference/derivationReference;
  columnas explícitas autoritativas. Rechazo previo de claves/tipos no admitidos
  con fila/ID/clave; sin mutaciones parciales ni cambios de semántica física.
- UI-001: base correctiva v0.17.1, no reescritura del tag anterior ni historia.
- UI-002: formato oficial R2026b `.m`+`.xml`, generado/normalizado por App Designer;
  shell visual editable con startup mínimo, layout de workflow dinámico en View.
- UI-003: core y controlador de búsqueda auditados intactos. UI sin ecuaciones.
- UI-004: SI visible inicialmente; no selector de unidades ambiguo ni defaults físicos.
- UI-005: PCT para parfeval de operaciones completas, no parfor del optimizador;
  pruebas previas N1/4/16 no demostraron aceleración numérica.
- UI-006: snapshots, operationId, epoch, una operación/escritor y cancelación real.
- UI-007: guardado temporal nativo y adopción explícita; sin autosave ni formato nuevo.
- UI-008: el proyecto declara software0.18; whitelist de EngineeringResult aditiva,
  sin modificar schemas físicos/envelope ni referencias históricas de ejecución.
- UI-009: tema claro local explícito para evitar texto oscuro sobre controles
  heredados del tema oscuro de MATLAB; no cambiar preferencias del usuario.
- OPEN DECISION: dimensiones reales, fuentes, regiones/bounds, dominios y targets
  de rendimiento siguen requiriendo al ingeniero. Fixtures no son recomendaciones.

## Construcción v0.17

- CTS-001: constructor determinista y familia pequeña, no otra física/search.
- CTS-002: líneas de pivotes + offsets upright, no renombrar XYZ globales.
- CTS-003: radio circular efectivo declarado, no inferido del descargado.
- CTS-004: toe/camber/clocking explícitos y reflexión/rotación nativas.
- CTS-005: wheelbase/track aplicable físicos; masa/CG no consumidos.
- CTS-006: readiness de inputs sin build/solves; bindings ya registrados pueden
  reconstruirse algebraicamente. Nominal y BUMP explícitos separados.
- CTS-007: reutilizar builder/assessment/quality históricos por adapters puros.
- CTS-008: adopción atómica con origin binding; sin borrar históricos ni
  inventar recursos dependientes incompatibles.
- CTS-009: schemas físicos/envelope preservados, versiones elegibles explícitas.
- OPEN DECISION: datos reales, rueda efectiva, upright/hub/packaging, recorridos,
  targets/tolerancias, incertidumbre y validación experimental.
[Contrato](concept-to-seed.md).

## Capa de proyecto v0.16

- PRJ-001: consumidor fsd.project con structs/MAT; capas físicas independientes.
- PRJ-002: reutilizar DesignParameter/Specification y catálogo de métricas,
  añadir confirmación/origen sólo en el wrapper conceptual; no otro evaluador.
- PRJ-003: inclusión de piloto explícita; CG total operativo, sin CG inventado.
- PRJ-004: derivación v0.9 condicionada a inputs/contactos/gravedad declarados;
  v0.10 no auto-adaptado sin cuatro paths/tyres y demás inputs explícitos.
- PRJ-005: preparar sin forwards ni búsqueda; ejecutar sólo por acción explícita;
  searchSettings es adaptador puro de las opciones históricas, no optimizador.
- PRJ-006: snapshots originales, ledger separado y compatibilidad selectiva.
  Dependencias justificativas conceptuales adicionales deben declararse.
- PRJ-007: MAT versionado de fuentes fiables; sin migración ni autenticación
  criptográfica ficticias. Readiness no certifica el ledger ni convergencia.
- OPEN DECISION: datos/hipótesis/arquitecturas/targets de un coche REAL, criterios
  experimentales de confirmación, modelos de prestaciones/neumático para generar
  targets, robustez continua y eventual adaptación explícita v0.10.
- LOW conservados: V14-OBS-01 título/exponente Ackermann; V15-OBS-01 diagnóstico
  AXLE en actuación; V15-OBS-02 ejes en intervalos extremadamente pequeños.

## Cerradas para v0.15

- ACS-001: suspensión seed fija, actuación geométrica variable de una esquina;
  fábricas v0.7/v0.8, BUMP y rocker existentes, controlador v0.12 sin modificaciones.
- ACS-002: cinco roles globales nominales; eje orientado fijo con punto canónico
  de dos DOFs. No inventar montaje/local frame ni DOF axial redundante.
- ACS-003: geometría nueva deriva longitudes y nueva asociación de coilover;
  spring rate/preload conocidos, FIXED/RANGE como constraints, no FREE mecánico.
- ACS-004: registro nominal ACT opcional para preflight HARD sin fuentes falsas;
  catálogos/scopes aditivos, ROCKER_ANGLE nativo sin gate innecesario de MR.
- ACS-005: ninguna proyección auxiliar de spec; familias individuales conservadas,
  límites mecánicos declarados respetados, F01-1 y signos nativos intactos.
- ACS-006: builders recuperables en allowlist cerrada; desconocidos relanzados;
  snapshot completo/replay sin forward solves y cache local por solicitud SI exacta.
- ACS-007: DIRECT ACTING no soportado por física histórica; no adaptador ficticio.
- OPEN DECISION: inputs/targets/tolerancias reales del coche, validación experimental
  y por refinamiento de malla, ramas continuas, bearings, fuerzas estructurales,
  buckling/compliance, montaje y colisiones CAD. [Contrato](actuation-geometry-synthesis.md).

## Cerradas para v0.14

- STS-001: extender privadamente bindings y pipeline de eje; schemas públicos
  nuevos0.14, sin ampliar silenciosamente APIs v0.12/v0.13 ni duplicar optimizador.
- STS-002: endpoints de diseño libres si autorizados; rack nativo rígido con
  traslación compartida, longitudes derivadas y cambios registrados por candidato.
- STS-003: referencia BUMP/ROLL rack cero exclusivamente; rearAxleX y límites
  de rack explícitos. Grids independientes no son cierre simultáneo roll–steering.
- STS-004: adaptadores existentes RACK/BUMP/ROLL, guard local con inner actual,
  Ackermann gaps/giros nativos; score/pesos/escalas v0.11, HARD antes de disponibilidad.
- STS-005: contexto/identidad física separados, evidencia por invocación y replay
  sin solves; allowlist de degeneraciones nuevas cerrada, errores desconocidos rethrow.
- STS-006: benchmark alcanzable y comparación separada contra métricas cero para
  hacer visible el compromiso físico; no confundir objetivos o declarar otro ganador.
- STS-007: leyendas externas y lienzo amplio en wrappers, core gráfico compartido,
  sin rediseñar el plot/evaluator v0.11 ni cambiar unidades/curvas.
- OPEN DECISION: mounting/travel/targets/pesos/escalas/tolerancias reales,
  continuidad y ramas globales, validación experimental, compliance/pinion,
  packaging de movimiento y grid simultáneo. [Contrato](steering-geometry-synthesis.md).

## Cerradas para v0.13

- AXS-001: dos seeds explícitos con referencia completa común; FRONT/REAR
  históricos, sin generar la esquina ausente ni masas/CG ficticios.
- AXS-002: reutilizar cornerSpace/buildCore/coordinateCore/bumpQuality y el
  boundedDirectSearch original; no refactor ni otro optimizador.
- AXS-003: vínculos sólo entre mismos roles/componentes declarados FREE/RANGE,
  Y=0, exactos en seeds; intersectar bounds y eliminar DOF dependiente.
  Simetría seleccionada no implica simetría completa ni de curvas.
- AXS-004: dos BUMP nuevos por eje válido y ROLL opcional nativo con ángulos,
  heave y opciones explícitos; source aliases ligados al mismo wrapper físico.
- AXS-005: un candidato/assessment v0.11 para todo el eje, calidad bilateral y
  de planes solicitados; clasificación primaria sin perder diagnósticos por lado.
- AXS-006: allowlist física v0.12 intacta; conservar fuentes independientes
  disponibles ante fallo de otro análisis, sin score/estado ficticio ni catch universal.
- AXS-007: snapshots completos y replay sin solves; sweeps e internal corner
  solves separados del presupuesto E. Reporting/MAT consumen datos, no cálculos físicos.
- OPEN DECISION: datos/targets/pesos/tolerancias reales, validación experimental,
  ramas/continuidad global, simetría completa/planos desplazados, nuevos adapters
  inversos y robustez. [Alcance y límites](axle-level-synthesis.md).

## Cerradas para v0.12

- SYN-001: capa consumidora synthesis, structs/MAT y APIs pequeñas, sin refactor
  de solvers/evaluador ni nueva tecnología. Seed de una esquina obligatorio.
- SYN-002: cuatro pivotes UCA/LCA chasis, XYZ por bindings v0.11; límites/fixed
  explícitos, ningún outboard/rack/actuation sin adapter completo.
- SYN-003: coordenadas normalizadas, endpoints/frozen/seed explícitos; caché
  por igualdad exacta de coordenadas físicas dentro de un único espacio.
- SYN-004: BUMP nuevo por geometría única válida; cinco métricas, preflight
  rechaza otros pipelines y source identities fijadas antes de buscar.
- SYN-005: polling local determinista con presupuesto/multiseed, sin
  penalización HARD ni pesos implícitos; ganador sólo con score completo.
- SYN-006: guard local orientation/rcond derivado del cierre histórico;
  adicional a convergencia, sin afirmar unicidad/continuidad global certificada.
- SYN-007: conservar todos los records/attempts, clasificaciones y tradeoffs;
  validar evidencia y replay sin solves. Tema local oscuro y claro explícito.
- SYN-008 (F-01): snapshot canónico al ejecutar y wrapper de evidencia BUMP;
  no provenance inferida al load ni autenticidad criptográfica prometida.
- SYN-009 (F-02): allowlist cerrada BUILDER/BUMP/ANALYSIS; desconocidos relanzados.
  Failure records sin fuentes/score ficticios; conservar sweep anterior al fallo.
- SYN-010 (F-03): single plot directo, comparación sólo >=2; sin elegibles se
  muestran intentos/diagnósticos/NO_AUTOMATIC_WINNER, no una solución sustituta.
- OPEN DECISION: targets/escalas/pesos reales, ramas globales/recorrido continuo,
  validación experimental y adapters físicos de las familias aún no reconstruidas.
  [Contrato y límites](inverse-suspension-synthesis.md).

## Cerradas para v0.11

- DTE-001: separar parámetros, targets/constraints y assessment; structs/MAT,
  model/analysis existentes, sin otra capa OO/paquete ni tecnología nueva.
- DTE-002: rol compatible con v0.9 separado de provenance/availability;
  unknown vacío; límites/bindings no inferidos ni recomendaciones FS.
- DTE-003: catálogo/adaptadores cerrados de 23 métricas ya disponibles;
  sourceId/tipo/scope/coordenada/referencia explícitos, condiciones rack/roll SI.
- DTE-004: interpolar target lineal, jamás actual; igualdad de coordenada
  scalar; RMS trapezoidal sólo edges válidos, PASS exclusivamente muestreado.
- DTE-005: HARD violado incluso parcial invalida respecto al spec; missing no
  PASS; SOFT conserva residuales sin invalidación automática. Score opt-in.
- DTE-006: validar fuente nativa una vez por llamada pública; core seguro sin
  validators/solvers en loops; validator del assessment reconstruye resultados.
- DTE-007: HP fixed/box nominales con tol explícita; sin packaging cert.
- DTE-008: regla explícita de espejo sólo BUMP side-independent, no steering.
- Base Git confirmada en comprobación final: v0.10.0, main y HEAD apuntan a
  18ff78e7b4f1d64bb2ff75375cac28c89fa64ce5 (baseline real 471).
  Se rectifica la observación inicial sobre ausencia del tag. No se crea ni
  modifica ningún tag, rama, commit o main.
- OPEN DECISION: targets/escalas/tolerancias reales, normativa verificada,
  simetría steering/roll, conectividad más fina, continuous verification y
  propagación de incertidumbre. No se completan con valores típicos inventados.

## Cerradas para v0.10

- GST-001: siete coordenadas y orden Rx(phi)*Ry(theta), conforme al prompt;
  se conservan marcos/signos/unidades históricos.
- GST-002: vertical tire unilateral opcional con kt/R0/provenance explícitos;
  único plano road, no círculo camber-dependent ni damping.
- GST-003: CG suspendido derivado; mu móviles en WC; cero sólo aproximación explícita.
- GST-004: U canónica, pp C1 por segmentos y derivatives del mismo pp;
  fuentes reales vs ideales declaradas, cero re-solves en evaluación.
- GST-005: Newton amortiguado base MATLAB, bounds/scales/tolerancias explícitas;
  multistart con UNIQUE_ONLY o LOWEST_ENERGY_STABLE, sin unicidad global prometida.
- GST-006: estabilidad desde H global escalado, gates c2 F-01/knots/contactos;
  curvatura no fiable no inventa rigidez ni invalida fuerza por sí sola.
- GST-007: factory en model y validación/pp downstream en analysis, sin ciclos.
- OPEN DECISION real: datos kt/R0/CG de mu, convergencia de path/mediciones,
  selección física entre ramas y extensión fixed-rack no nulo.
  Ninguna se completa con datos FS típicos inventados.

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
