# Registro de decisiones

## ARB-010 — V23-F-02: preservación por campo de la declaración cargada

26 octubre 2026. Extender el snapshot transitorio de V23-F-01 a la definición
completa del escenario y su representación visual. Comparar exactamente los
controles con su representación cargada y fusionar únicamente campos editados.
No reconstruir desde texto campos no editados: 17 dígitos no garantizan conservar
una ida/vuelta de unidades, la clase single, la forma de vectores o la ausencia
de un campo. Packaging conserva además los datos de volumen que la UI no muestra.
Se descartan tolerancias de equivalencia física, normalizaciones globales,
supresión de revisiones y modificaciones de compatibilidad: ocultarían cambios
o afectarían contratos correctos. Se evita un framework genérico de formularios;
la solución permanece dentro de ArbView. Los validadores, revisiones y STALE
existentes deciden el efecto de las declaraciones resultantes.
No cambia el modelo matemático ni el esquema persistente. El cambio explícito
de motor mantiene la ruta de creación de plan/opciones del nuevo motor.
[Contrato y evidencia](v0.23-f02-validation.md). Esta es una decisión de la
corrección actual, no una justificación retrospectiva de la implementación previa.

## ARB-009 — V23-F-01: frontera numérica de presentación

Convertir datos numéricos a double antes de la aritmética de unidades, no después
del redondeo entero. Mantener %.17g y conservar el plan/celdas cargados que no se
editen evita reescribir tipo, valor SI o campos ausentes de una declaración parcial.
Una edición numérica real se interpreta como double; no se reconvierte al entero
original. Una edición sólo de procedencia conserva el número original.
Se descartan rechazar enteros válidos y normalizar ahora el modelo/proyecto/MAT:
el defecto está en la UI y esas alternativas alterarían contratos no afectados.
Estado transitorio por estudio, sin esquema persistente nuevo ni caché de cálculo.
No cambia la física ni se reconstruye retrospectivamente ninguna motivación.
[Evidencia focalizada](v0.23-f01-validation.md).

## ARB-002…008 — implementación autorizada v0.23,25 octubre2026

Estas decisiones pertenecen al desarrollo0.23, no reconstruyen motivaciones
históricas desconocidas. El estudio y las precisiones del usuario aprueban la
física general; los siguientes contratos concretan su implementación:

- **ARB-002:** separar recurso equivalente lineal de geometría coaxial. Ambos
  comparten energía/trabajo virtual, no capacidades ficticias. Descartadas dos
  rigideces de rueda independientes y una conversión automática de roll stiffness
  a toda la ley de fuerzas: pierden acoplamiento o necesitan hipótesis ausentes.
- **ARB-003:** coordenadas de ambos brazos sobre el mismo eje orientado, referencia
  libre UNKNOWN/ZERO_AT_INSTALLATION/DECLARED_FREE. La instalación descargada
  define psiFree=alphaR_install−alphaL_install. Descartado inferir cero por ausencia.
- **ARB-004:** compartir aritmética histórica círculo/esfera y transformación de
  puntos materiales; conservar ramas/ángulo continuo. PCHIP interpola pickup XYZ;
  el cierre analítico se resuelve sobre ese mismo camino y sus derivadas implícitas
  dan energía/gradiente/Hessiano coherentes. Descartados solver duplicado e
  interpolación independiente de ángulo/fuerza/rigidez por errores de cierre/trabajo.
- **ARB-005:** ley conocida en puertos con alcance explícito, o GJ/L circular
  excluyente. Dimensionamiento inverso escalar desde target del usuario. No inferir
  material, longitud activa, deformación de brazos o un óptimo de vehículo.
- **ARB-006:** incrustar Uarb/gradiente/Hessiano en los pares de coordenadas de
  rueda del GLOBAL_STATIC existente. Mantener Newton, balances externos y contacto
  unilateral; guard adicional de segmentos/ramas. Descartado un resorte directo
  adicional de roll o anular ARB en rueda sin contacto: cambiarían la energía física.
- **ARB-007:** separar recepción exacta de ejecución de la proyección física de
  reutilización, como exige V22-F-02. Rigidez desconocida no bloquea cinemática;
  material almacenado no invalida ley conocida independiente. No usar igualdad
  de curvas como prueba de equivalencia. Soportes sin posición/radio no bloquean
  cierre/fuerzas, pero no certifican packaging. No modificar snapshots MAT antiguos.
- **ARB-008:** packaging acotado mediante primitivas existentes y dimensiones
  explícitas. UI nueva sólo para declaraciones, magnitudes, comparación, sizing y
  asociación global. Conservar candidato local de curvatura separado de tangente
  bilateral; no presentar rigidez/estabilidad certificadas en extremos o knots
  no resueltos. No fabricar radios de apoyos desde una línea geométrica.

**ARB-001 permanece abierto en su significado histórico:** INTEGRATED requiere
optimización conjunta futura; POST_DESIGN/DISABLED son estrategias de producto,
no nuevos algoritmos ya completados por sumar energías en el equilibrio estático.
Contratos, ecuaciones, alternativas y límites: [anti-roll-bar](anti-roll-bar.md).

## TIR-006/007/008 — correcciones de auditoría v0.22, 24 octubre 2026

Decisiones posteriores a CHANGES REQUIRED, sin alterar el resultado original:

- **TIR-006:** compartir normalizeRequest entre evaluación y presentación. La UI
  representa la secuencia exacta de canales y muestra ausencias en blanco.
  Descartado duplicar defaults en callbacks, ordenar/descartar canales o aplicar
  silenciosamente un escenario durante LOAD. Evita divergencia del contrato público.
- **TIR-007:** conservar prepared.context completo y derivar una proyección física
  sólo al clasificar compatibilidad. Descartado reemplazar el contexto guardado:
  rompería reconstrucción de MAT0.22 y podría confundir reutilización con recepción
  de una operación distinta. La selección estructural sigue ramas/capacidades de
  la familia y estados efectivos; no usa coincidencia de arrays como prueba.
- **TIR-008:** normalizar numerics una vez en create, antes de identidades, y
  exigir double canónico en validate. Enteros con roundtrip exacto dentro de
  flintmax y single son admisibles; conversiones inseguras se rechazan. Descartado
  convertir coeficientes en cada ecuación o aceptar recursos que fallen después
  en funciones que exigen floating point. No cambian física ni tolerancias.

Contratos y límites en [tire-models-foundation](tire-models-foundation.md);
evidencia en [correcciones](v0.22-audit-corrections.md).

## GSE-001/002/003 — integración v0.21,23 octubre2026

Decisiones nuevas del desarrollo autorizado, sin atribución retrospectiva:

- GSE-001: generar paths ACTUATION_BUMP_3D en cada GLOBAL_RUN explícito; evita
  referencias recursivas a cuatro ledgers y obliga a usar la geometría/actuación/
  coilover vigentes. Alternativa descartada: copiar curvas BUMP/MR por ID sin
  comprobar contexto. Los paths ideales históricos sólo son oráculos declarados.
- GSE-002: masa y CG proceden del concepto y conceptPreparation existentes; se
  evita una segunda contabilidad editable independiente. Los contactos conceptuales
  sólo alimentan la referencia v0.9; el sistema global usa WC reales transformados.
- GSE-003: exponer globalStaticSolverSettings como envoltorio del normalizador
  histórico. Readiness puro, sin duplicar algoritmo/presupuestos ni llamar solver.

El esquema lógico y almacenamiento se mantienen por compatibilidad; sólo se añade
una familia de escenario/payload al consumidor. Las posiciones de esquinas se
comprueban en el frame canónico: izquierda Y<0, derecha Y>0, estaciones traseras
detrás de las delanteras. No se fuerza igualdad de geometrías ni simetría implícita.
No justificación nueva de PCHIP/Newton/tolerancias históricas: referencias/motivos
documentados en [contrato0.10](global-static-equilibrium.md); lo desconocido sigue
pendiente de reconstrucción. [Contrato nuevo](guided-global-static.md).

## Integración guiada v0.20 — decisiones nuevas

- **GAM-001:** reutilizar fábricas, preparación, ejecución y validadores históricos
  v0.7/v0.8/v0.15. Alternativa descartada: implementar ecuaciones o un solver en la
  UI, que duplicaría convenciones y referencias verificadas. No nueva física.
- **GAM-002:** configurar/adoptar actuación y coilover en una transacción de proyecto,
  conservando exactamente la geometría y el ledger. Alternativa descartada: adoptar
  sólo hardpoints visibles y reconstruir después un coilover aproximado, que puede
  perder identidad, procedencia o límites. `[]` elimina mecánica explícitamente.
- **GAM-003:** tres acciones nuevas con reconstrucción semántica compartida y recepción
  RF-01/02/03. Reutilizar SPECIFICATION/SYNTHESIS en lugar de otro protocolo worker.
  Se conserva sólo el padre de adopción en transporte; el owner mantiene el historial.
  Validación canónica por sí sola no demuestra correspondencia con lo solicitado.
- **GAM-004:** subvista nativa independiente, tablas y gráficas sobre evidencia guardada;
  mm, grados, N y N/mm en fronteras, SI dentro. Alternativa descartada: rediseño global,
  simulador gráfico o recomputación al seleccionar. La vista difiere gráficos ocultos
  y limpia poses inválidas. Drafts deben aplicarse; no se guarda una copia UI del modelo.
  En validación nativa, la primera página del grupo de pestañas interno se mostraba
  vacía y sus gestos agotaban20s; se eligió el patrón existente de selector/paneles
  superpuestos, que permite controlar explícitamente visibilidad. No se atribuye una
  causa interna a MATLAB que no se haya demostrado. Capturas diagnostic del estado
  inicial y ui-before-edit de la configuración corregida, además de las repeticiones
  del informe; las tablas conservan sus gestos originales.
- **GAM-005:** requerir velocidad y procedencia explícitas para el flujo mecánico guiado,
  manteniendo intacto el default de reposo de las APIs históricas directas. No inferir
  velocidad del grid ni imponer límites físicos estimados. No usar un rocker ficticio
  para Direct Acting. Targets/normalización son declaración del usuario, no síntesis
  fundamentada desde prestaciones (prevista v0.25).
  Selectores físicos sin recurso previo permanecen UNSELECTED y se limpian al cambiar
  de contexto; no usar la primera opción o la selección de otro corner como dato físico.
- **GAM-006:** datos sin nuevo schema; ampliar software0.20 en los validadores que lo
  necesitan. Mantener MAT0.19 y exactitud canónica, no migrar proyectos viejos al abrir.
  Si falta worker, ofrecer Cancel/Start worker/Run synchronously explícitos. No fallback
  silencioso ni nuevo backend. Costes medidos en casos representativos, sin límites
  arbitrarios de historial, benchmarks extensivos u optimización marginal.

Justificación histórica: se conservan las razones que ya constan en ACS/SD/ACT/MR y
PKG. Cuando no conste el porqué original de una elección, **OPEN DECISION — reconstruir
motivación histórica**; las razones nuevas anteriores sólo justifican esta integración.
Direct Acting, modelos estructurales, gas/histéresis/fabricación y nuevas hipótesis
quedan fuera de v0.20. No hay una decisión física abierta necesaria para este alcance.
[Contrato y alternativas](guided-actuation-mechanics.md) · [validación](v0.20-validation.md).

## Packaging v0.19

- PKG-020 (V19-RF-03): la autoridad de recepción es la operación pendiente del
  propietario. Tras validar canónicamente el payload, reconstruir el contrato
  declarativo compartido con ejecución y vincular escenario, snapshot, motor,
  IDs, revisión, recursos, padre, plan y opciones reales. No ejecutar de nuevo
  un solver/búsqueda ni confiar en un fingerprint reenviado. Verificar también
  configuración y resultados no físicos de todas las operaciones. La evidencia
  transitoria referenceSweep permite verificar los targets ilustrativos sin
  repetir BUMP; SAVE/LOAD verifican contenido MAT solicitado. Sin modificar el
  formato persistido ni la física. Contrato, matriz y resultados en
  [RF-03](v0.19-rf03-operation-contract.md); se conservan los límites de latencia.

- PKG-010 (V19-F-01): selección estable por resultado/par/muestra y reconciliación
  explícita de Selection al cambiar Data/filtro; gestos reales de regresión.
- PKG-011 (V19-F-02): validación por componentes y límites de confianza sobre
  valores inmutables. Fusión de dos ledgers ya validados, no omisión de su
  validación externa. Clasificación masiva con el mismo core canónico. No caché
  global ni memoización de snapshots/proyectos completos: el prototipo de caché
  grande añadió coste y presión de memoria y fue retirado.
- PKG-012 (V19-F-02): request reducido al padre requerido, retorno incremental y
  recheck de epoch después de fusionar. No borrar registros ni reparentar resultados.
- PKG-013 (V19-F-02): DAG local reversible FSD_VALUE_GRAPH_V1 para MAT/PCT.
  Interning estructural por shape, campos ordenados y referencias exactas a hijos
  ya codificados; primitivas densas pequeñas por clase/shape/flags/bits íntegros.
  No hash aproximado ni caché de árboles originales. El umbral de128 elementos
  limita sólo el tamaño de claves; arrays mayores y sparse se guardan intactos.
  Leer también TEXT_V1 y MAT clásico0.16; no sidecars ni otra tecnología.
- PKG-014 (V19-F-02): conversión cooperativa cancelable, no backgroundPool en
  producción. La sonda de una suma trivial midió unos1.1GiB adicionales al
  activar el runtime de threads. Se conserva un único worker de ingeniería;
  no se cambia maxNumCompThreads, pools ajenos, física o datos. Busy/Completing
  y comprobación posterior de epoch protegen los callbacks cedidos.
- PKG-015 (V19-F-02): búfer local de32MiB para grafos MAT ya codificados durante
  el preflight. Evita una segunda codificación cuando caben; si no, se conserva
  la ruta por registro, sin recortar datos. Es presupuesto de trabajo I/O,
  no hipótesis física ni límite funcional. Se libera al terminar cada guardado.
- PKG-016 (V19-F-02): shutdown idempotente de View libera sus datos y callbacks
  Packaging -> View; no invalida snapshots externos ni cancela trabajo de pools
  prestados. Romper referencias de una vista cerrada no demuestra por sí solo
  una fuga; la retención del runtime y la RAM se miden aparte.
- PKG-017 (V19-F-02): guardado acotado0.19 también para historiales sin Packaging.
  La traza gráfica alcanzó síntesis/validación y localizó otro pico en SAVE del
  escritor antiguo. Se reutiliza la misma codificación reversible por registro;
  no se cambia el modelo lógico ni se omite validación. Lectura de MAT0.18
  conservada; ficheros nuevos con historial requieren el lector0.19. El escritor
  clásico permanece para proyectos sin Packaging y sin resultados.
- PKG-018 (V19-F-02): las vistas no se reconstruyen por VALIDATE/SAVE si proyecto
  y compatibilidad no cambian. Pestañas ocultas difieren gráficos hasta su visita;
  tablas e identidades se mantienen, y un cambio real invalida la presentación.
  Navegar entre vistas ya vigentes conserva muestra/cámara; no es una caché de
  ingeniería ni una autorización para reutilizar resultados físicos obsoletos.
- PKG-019 (V19-F-02): el codec reutiliza descriptores exactos de nombres de campos
  ordenados -> IDs de texto, sólo dentro de una codificación. La clave incluye
  cantidad, longitudes y UTF-16 íntegro; se visitan todos los valores y se conserva
  el orden original de registro de textos/nodos. No cachea subárboles originales.
  Caso nativo202228597bytes:31.5014s ->26.5799s en procesos frescos -nojvm,
  con grafo codificado exactamente igual (1622 nodos). Una pareja controlada,
  no una garantía universal de velocidad. Se descarta el Map al retornar.

- PKG-001: kernel analítico MATLAB; Navigation sólo contraste opcional. No nueva
  dependencia obligatoria, CAD cóncavo, fuerzas de contacto ni solver físico.
- PKG-002: modelos simplificados declarados por el ingeniero; radio efectivo no
  proporciona ancho/offset/llanta/freno. Espacio libre de llanta no es material.
- PKG-003: bindings nominales FIXED, pose UPRIGHT y cápsula SEGMENT con dos
  IDs explícitos. No se infiere un volumen completo desde conectividad o hardpoints.
- PKG-004: NOMINAL/BUMP almacenado en la primera cobertura integrada. Adaptadores
  ROLL/RACK/actuación móvil quedan pendientes de verificación; no composición ficticia.
- PKG-005: margen físico explícito, tolerancia numérica histórica separada;
  contactos exentos sólo por par/componente y justificación persistida/visible.
- PKG-006: compatibilidad canónica y recurso opcional; optimizador, scores,
  elegibilidad y modelos físicos históricos sin cambios.
- PKG-007: tras medir87,7s en una actualización, reemplazar la copia recursiva
  del padre por PackagingSourceReference con snapshot de dependencias verificadas.
  Sólo se omiten escenarios/recursos Packaging, que los motores nativos permitidos
  no consumen; la fábrica exige igualdad exacta de toda la preparación original.
  Se conserva el original completo en el ledger y su identity en la referencia.
  resultCompatibility comparte su lógica para el nuevo tipo, sin otro sistema
  de staleness, sin ejecución física y sin fingir CURRENT_EXECUTION.
- PKG-008 (histórica; escritura ampliada por PKG-017): detener una prueba propia
  que alcanzó24GB privados en un equipo de16GB
  durante SAVE; no aceptar el recorrido como PASS. Representar strings de forma
  reversible sin objetos string en la frontera MAT/PCT, preservando shape,
  missing, Unicode, tipos y valores numéricos. Escapar nombres reservados.
  Para Packaging, usar un único MAT con configuración y variables por resultado;
  conservar lectura0.16 y la escritura clásica para proyectos sin Packaging.
  No sustituir el historial completo por resúmenes ni eliminar sus evidencias.
- PKG-009 (histórica, sustituida por PKG-014): conversión pura en backgroundPool
  y cálculos/archivos únicamente en
  ProcessPool. Extensión explícita del Controller UI, no del controlador físico.
  Propagar cancelación y ownership durante ENCODING/EXECUTING/DECODING; no cerrar
  pools de threads compartidos. Verificar invariantes con los tests previos y
  nuevos, no asumir que un round-trip pequeño prueba un historial grande.
- OPEN DECISION PKG-PHYSICAL: dimensiones, fidelidad, contactos locales permitidos,
  márgenes de ingeniería y refinamiento adecuado deben fijarse para cada vehículo.
  Ningún fixture ilustrativo es una recomendación universal de Formula Student.
- OPEN DECISION PKG-CAPACITY: acordar tamaño de historial y límites de memoria/
  latencia aceptables antes de ampliar uso. El flujo completo validado conserva
  todos los registros, pero transporte/validación siguen siendo muy costosos.
  No prometer que más RAM o un pool mayor resolverán el coste sin medirlo;
  cualquier rediseño de identidades/historial requiere una tarea y auditoría propias.

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

## V21-F-01 — representación de neumáticos pendientes (2026-10-23)

Un neumático nativo ausente se representa con campos vacíos en su esquina;
readiness conserva la responsabilidad de diagnosticar los recursos pendientes.
La lectura directa de campos de `[]` impedía continuar proyectos válidos e
incompletos. Se descartan neumáticos sustitutivos y ceros porque inventarían
datos físicos. El marcador de dibujo se confirma al finalizar el refresco:
confirmarlo antes impedía reintentarlo tras un fallo. Se conserva la propagación
de errores; un catch general ocultaría fallos de programación. No se cambian
ecuaciones, unidades, modelos, esquema MAT ni normalización numérica existente.
Contrato y pruebas: [flujo global](guided-global-static.md),
[validación focalizada](v0.21-f01-validation.md).

## Tire Models Foundation —24 octubre2026

- **TIR-001:** alternativa C aprobada: familia nativa ligera y APIs públicas
  MathWorks opcionales, sin dependencia obligatoria de VDYNTIRE. La prueba26.2.3
  mostró distinto comportamiento Dugoff para el mismo kappa: mantener variantes
  identificadas, sin sustituir ni convertir silenciosamente la física aprobada.
- **TIR-002:** capacidad, rigideces y camber tienen leyes declaradas separadas.
  No inferir exponentes ni hipótesis despreciables de campos vacíos. MARK/REJECT
  no recortan ni extrapolan entradas. Camber thrust no implica capacidad óptima.
- **TIR-003:** recurso compuesto y proyección vertical; registry/revisiones y
  asignaciones existentes, no otro framework MAT/worker. Contexto global consume
  ID y componente vertical, no la revisión de fuerza completa.
- **TIR-004:** .tir mediante parser público proveedor, texto/parámetros/versiones
  plain IMPORTED_UNVERIFIED. No conversión nativa ni completitud experimental
  certificada. Adaptadores de importación/contraste no añaden identificación/TTC
  ni otro motor MF al proyecto/UI.
- **TIR-005:** estacionario Fx/Fy con dominios explícitos, sin Mz/radio efectivo/
  transitorios. Calidad de evidencia declarada y referenciada, sin certificar
  ensayos ausentes. Ecuaciones y límites: [contrato](tire-models-foundation.md).

Estas decisiones nuevas no reconstruyen motivaciones históricas desconocidas.
