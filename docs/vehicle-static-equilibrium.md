# Vehicle Parameters & Static Load Equilibrium — v0.9

## Alcance y significado físico

Dos problemas separados: distribución de reacciones verticales de cuatro
contactos y equilibrio LOCAL de una suspensión sobre un path prescrito.
No resuelve una pose común de chasis ni heave/pitch/roll simultáneos. Cuatro
roots independientes no garantizan un chasis rígido compatible.

Supuestos de cargas: suelo nominal horizontal, gravedad uniforme, estática,
sin aero, aceleraciones, fuerzas horizontales ni otras cargas externas.
No hay stiffness de neumático, ARB ni anti geometry. Los ejemplos son ASSUMED,
no setups óptimos ni datos aptos para fabricación.

## APIs

```matlab
vehicle = fsd.model.createVehicleParameters(definition, units);
fsd.model.validateVehicleParameters(vehicle);
identity = fsd.model.vehicleIdentity(vehicle);
fsd.model.validateVehicleIdentity(identity);
caseData = fsd.model.createVehicleLoadCase(vehicle, caseDefinition, loadUnits);
fsd.model.validateVehicleLoadCase(caseData, vehicle);
loads = fsd.analysis.analyzeStaticVehicleLoads(vehicle, caseData);
fsd.analysis.validateStaticVehicleLoads(loads, vehicle, caseData);
local = fsd.analysis.solveCornerStaticEquilibrium( ...
    springDamperModel, actuationGeometry, mechanicalAnalysisAtRest, support_N, options);
fsd.analysis.validateCornerStaticEquilibrium(local); % o fuentes externas explícitas
delta = fsd.analysis.compareStaticVehicleCases(vehicleA, loadsA, vehicleB, loadsB);
% Opcional: añadir equilibriumA, equilibriumB; exige demandas que correspondan a loads.
fsd.analysis.plotStaticVehicleLoads(vehicle, loads, figureHandle);
fsd.analysis.plotCornerStaticEquilibrium(local, figureHandle);
```

Para camino prescrito ideal, actuationGeometry puede ser []: se valida el
contrato PrescribedDamperPath de v0.8, no se fabrica una solución de rocker.
Con geometría explícita se verifica asociación incluso para ese camino.
Source/model/actuation/velocidades se validan una vez antes del core de búsqueda.
El equilibrio requiere wheelVelocity=0; damping no soporta carga estática.

## VehicleParameters: construcción independiente de suspensiones

Struct schema 0.9.0, frame X_REAR_Y_RIGHT_Z_UP, cornerIds [FL;FR;RL;RR].
Origen nominal entre contactos delanteros sobre suelo. X hacia atrás, Y hacia
derecha, Z arriba. Contactos conceptuales:
[0,-tF/2,0], [0,tF/2,0], [L,-tR/2,0], [L,tR/2,0].
No se equiparan Wheel Center y Contact Patch. Vías pueden ser diferentes.

Campos de entrada comunes:

- wheelbase, frontTrack, rearTrack: longitudes positivas;
- gravity_mps2: positiva y obligatoria, sin default 9.81;
- operatingConfiguration: identificador operativo escalar no vacío;
- massMode: TOTAL_MASS o COMPONENT_MASSES;
- sourceKind: KNOWN/FIXED/RANGE/FREE/TARGET/DERIVED/ASSUMED/RULE/UNSPECIFIED;
- unsprungMass opcional: cuatro masas no negativas, desconocidas como NaN;
- contactPoints opcional: matriz 4x3 FL/FR/RL/RR, finita sobre Z=0 nominal;
- metadata opcional para notas/presentación, excluida de identity.

units exige length=m/mm, mass=kg, gravity=m/s^2. Conversión exclusivamente
en construcción; definitionSI conserva inputs canónicos. No hay g/mm ambiguos.
Un CG es fila 1x3; NaN significa no disponible por coordenada. Inf no permitido.

TOTAL_MASS requiere totalMass>0 e includes (inventario explícito de items).
cg puede faltar o tener coordenadas NaN. No permite añadir components.
FrontWeightFraction/rearWeightFraction opcionales en [0,1], nombres de entrada
frontWeightFraction/rearWeightFraction; fR=xCG/L, fF=1-fR. Ambas fracciones o
CG redundantes se comprueban a 1e-10 relativo de escala (software, no metrología).
Con contactos explícitos de X común por eje, xCG=xFront+fR*(xRear-xFront).
Con stagger se rechaza la fracción como representación alternativa de CG:
esa equivalencia no existe sin más condiciones de distribución.
Una fracción puede derivar X faltante en TOTAL_MASS, nunca Y/Z.

COMPONENT_MASSES requiere components, un array de structs con:
id único, mass>0, cg opcional 1x3, includes (items únicos), sourceKind.
La masa base incluye SÓLO los items declarados; piloto/combustible/lastre
añadidos deben tener inventarios disjuntos. Omitir componentes ausentes, no
crearlos con masa cero. Rechaza IDs repetidos, items repetidos o masa/CG total
introducidos en paralelo. No puede detectar un inventario humano falso:
la veracidad de lo que físicamente incluye la masa base requiere trazabilidad.

M=sum(m_i), CG=sum(m_i*r_i)/M. Composición se calcula por coordenada sólo si
todos los componentes conocen esa coordenada. Posición faltante de piloto
no se supone en el asiento ni en el CG del vehículo. Masa total sigue disponible.
Componentes DERIVED no convierten supuestos en mediciones: se conserva su
provenance completa. No se reemplaza CG faltante de componente con una
fracción global (sería otra fuente/hipótesis, no composición de masas).

Altura CG se conserva y no modifica cargas niveladas por sí sola. No se exige
Y/Z para obtener carga de eje cuando X, M y ejes longitudinales son conocidos.

Contactos explícitos pueden tener stagger y vías reales independientes,
con izquierda/derecha ordenadas por Y. Deben tener rango tres bien condicionado
en equilibrio escalado; no se acepta línea/polígono degenerado. Se usan los
contactos reales, no las vías declaradas como sustituto de sus coordenadas.
Las dimensiones siguen siendo parámetros nominales; no se declara equivalencia
automática entre esos targets y la geometría real. Contactos conceptuales se
etiquetan ASSUMED_CONCEPTUAL; contactSourceKind opcional conserva procedencia.

## Masa suspendida/no suspendida

Unsprung mass es parte del total, NO masa que se suma de nuevo.
M_sprung=M_total-sum(m_u) sólo si todas las cuatro masas son conocidas.
Suma de masas no suspendidas conocidas no puede exceder total. Cero es un
dato explícito; NaN jamás se convierte silenciosamente en cero. Sin desglose,
cargas neumático siguen calculables, soporte local dependiente no.

Modelo reducido: support_i=N_i-m_u_i*g. Supuestos adicionales:
masa concentrada por esquina y transferencia vertical local idealizada,
sin aero ni anti geometry. No son fuerzas exactas de todos los links 3D.
SupportForce es demanda generalizada en rueda, no fuerza axial de muelle.
Si la resta es negativa se informa NEGATIVE_LOCAL_SUPPORT_DEMAND y se conserva
candidateSupportForce como diagnóstico; no se pasa al solver como soporte
elástico positivo. Medidas inconsistentes con balances conocidos no generan
support aceptado. Con CG parcialmente desconocido sólo se verifican balances
conocidos; no se certifica el equilibrio completo.

## Ecuaciones e indeterminación

W=M*g. A=[ones; contactX'; contactY']; b=W*[1;xCG;yCG].
A*N=b: suma N=W, suma xN=W*xCG, suma yN=W*yCG. Reacciones en N, no kg.
Con ejes X=0/L: N_front=W*(L-xCG)/L, N_rear=W*xCG/L.
Con X común por eje real, se traslada explícitamente mediante xCG-xFront
y xRear-xFront. Con stagger esas sumas pueden NO ser únicas.

Escalado: longitud S=max(wheelbase, tracks, abs(contact coordinates)).
A_scaled=A./[1;S;S]; b_scaled=b./[1;S;S].
SVD de rango tres: particular N0 y un vector nulo n:
N=N0+lambda*n. N0 es representante algebraico de mínima norma, NO cargas
únicas publicadas. n se normaliza a max(abs(n))=1 y primer componente
significativo positivo; invertirlo sólo reparametriza lambda, no la familia.

N_i>=0 da lambda>=-N0_i/n_i si n_i>0, y <= si n_i<0.
Intersectar intervalos; n_i numéricamente cero exige N0_i>=0.
Sin intervalo: NO_FEASIBLE_FOUR_CONTACT_LOADS, sin truncar cargas físicas.
Publicar family, bounds por rueda y crossweight bounds, NO una selección.
Si falta X/Y: INSUFFICIENT_CG_FOR_CORNER_LOADS; degreeOfFreedom y
knownConstraintRank reflejan filas conocidas. Familia completa queda NaN.

Umbrales de balance conservados: fuerza 1e-10*max(W,1 N), momento
fuerzaTolerance*S. NO autorizan cargas negativas. Layout exige
sigmaMin/sigmaMax>sqrt(eps). La política de roundoff siguiente sustituye el
antiguo snapping absoluto, sin modificar ecuaciones físicas ni mediciones.

### SL-32: roundoff, frontera y viabilidad separados

Matrices M escaladas por S; todas sus filas multiplicadas por cargas tienen
unidades N, incluida la cuarta fila CW cuando existe. Para M*x=h:

```text
gamma = 32*eps/(1-32*eps)
r = M*x-h
eRows = gamma*(abs(M)*abs(x)+abs(h))
gap = sigmaMin(M)-gamma*sigmaMax(M)
eLoad = (norm(r,2)+norm(eRows,2))/gap
```

gamma es un margen de aritmética double para los productos cortos, construcción
de coeficientes y factorización/solución de matrices de máximo 4x4: 32 acumula
un presupuesto conservador de operaciones, NO una constante de ingeniería.
El residual observado se incluye y el denominador amplifica sensibilidad por
conditioning. Esta política de cálculo no es una certificación rigurosa de
todos los errores internos de BLAS/LAPACK ni incertidumbre instrumental.
Fundamento: [eps de MATLAB](https://www.mathworks.com/help/matlab/ref/double.eps.html)
y [precisión/sensibilidad de SVD, Moler §10.7](https://www.mathworks.com/content/dam/mathworks/mathworks-dot-com/moler/eigs.pdf).
Las expresiones y el margen SL-32 son la política explícita de este proyecto,
no una tolerancia física atribuida a esas fuentes.

Para la dirección n normalizada:
eDirection=(norm(As*n)+gamma*sigmaMax(As)*norm(n))/gap.
Un coeficiente no resoluble frente a ese error se trata como cero numérico;
su particular se verifica con eLoad y sensibilidad eDirection*(W+norm(N0)).
Cada límite lambda=-N0_i/n_i lleva presupuesto en N:

```text
eLambda = (eLoad+abs(lambda)*eDirection)/(abs(n_i)-eDirection)
          +2*eps(abs(lambda))
```

family.rawLambdaInterval_N conserva los límites sin corrección.
lambdaBoundaryBudget_N=eLower+eUpper. Un intervalo claramente positivo conserva
su extensión; una separación lo-hi mayor que este presupuesto sigue EMPTY.
Si abs(hi-lo) está dentro del presupuesto, se propone determinísticamente
lo+(hi-lo)/2. Se reconstruye N0+lambda*n, con error eLoad+abs(lambda)*eDirection
+gamma*norm(abs(N0)+abs(lambda*n)), y se comprueban las TRES filas originales.
Sólo un negativo dentro de ese presupuesto puede corregirse a cero; valores
positivos pequeños se conservan. Tras corregir se exige, por fila:
abs(M*N-h)<=gamma*(abs(M)*abs(N_raw)+abs(h))+sum(abs(M),2)*eLoad_candidate.
Los extremos de intervalos no degenerados reciben el mismo control.

POINT_WITHIN_ROUNDOFF representa un intervalo puntual a resolución numérica:
admissibleDimension=0, pero degreeOfFreedom algebraico sigue siendo 1.
INTERVAL representa dimensión admisible 1; EMPTY o UNAVAILABLE no asignan
dimensión admisible. endpointLoads_N publica extremos verificados y bounds
proceden de ellos; particular y nullDirection preservan la parametrización.
Ningún punto se selecciona silenciosamente como cornerLoads en UNDERDETERMINED.
El diagnóstico numérico puntual no garantiza distinguir un CG unos ulps fuera
de uno exactamente sobre la frontera. No se amplía con tolerancia física.

CW usa el presupuesto de su matriz 4x4 COMPLETA y vuelve a verificar la cuarta
fila ORIGINAL tras una corrección, sin cambiar crossweightFraction solicitado.
Una normal negativa más allá de normalRoundoffBudget_N implica
INFEASIBLE_CROSSWEIGHT aunque el residual satisfaga forceTolerance_N.
NUMERICAL_BOUNDARY_COMPATIBLE declara resolución limitada cerca de cero, no
factibilidad física garantizada por una precisión inexistente. El candidato
sin corregir sigue en candidateCornerLoads_N; cargas y soporte aceptados
quedan NaN cuando se rechaza. Los validadores reconstruyen estos diagnósticos.

MEASURED_CORNER_LOADS no utiliza esta corrección: preserva exactamente las
cuatro mediciones canónicas SI, incluyendo 1e-12 N y cero; ORIGINAL_MEASUREMENTS
no afirma que satisfagan balances. Conversión de unidades sólo en entrada.

Support se calcula SIN max/clipping. Presupuesto exclusivo de resta/producto:
supportRoundoffBudget_N=2*eps*(abs(N)+abs(mu*g)). Negativo más allá del presupuesto
es NEGATIVE_LOCAL_SUPPORT_DEMAND; negativo dentro del presupuesto es
LOCAL_SUPPORT_NUMERICALLY_UNRESOLVED. Ambos conservan candidateSupportForce_N
y NO publican demanda aceptada. Cero exacto es soporte nulo, no prueba de una
raíz aislada, estabilidad o chasis equilibrado. Positivo se conserva, sin snapping.

## Cierre explícito de distribución

caseDefinition.mode y sourceKind obligatorios; metadata opcional.
loadUnits: force=N/kg_equivalent, crossweight=fraction/%; default N/fraction.

- UNDERDETERMINED: conserva familia; no permite cuarto dato implícito.
- CROSSWEIGHT_SPECIFIED: crossweight o crossweightFraction canónica.
  Añade fila [0,1,1,0], verifica unicidad, balance y no negatividad.
  Fuera de intervalo: INFEASIBLE_CROSSWEIGHT; candidato sólo diagnóstico.
  Matriz singular: CROSSWEIGHT_NOT_UNIQUELY_RESOLVABLE.
- ASSUMED_SYMMETRIC_BASELINE: sourceKind debe ser ASSUMED. Sólo Ycg=0,
  contactos espejo en cada eje y X común permiten repartir N_eje/2.
  De otro modo SYMMETRY_ASSUMPTION_INCOMPATIBLE, sin cargas inventadas.
- MEASURED_CORNER_LOADS: measuredCornerLoads (cuatro normales no negativas).
  No ajusta mediciones; calcula suma, ejes, lados, diagonales, CG inferible
  XY y residual [N,Nm,Nm]. Estados CONSISTENT/INCONSISTENT o CG_NOT_FULLY_SPECIFIED.
  La tolerancia es numérica, NO tolerancia instrumental. No se añade una
  aceptación metrológica por defecto.

CW=(FR+RL)/W; diagonal complementaria=(FL+RR)/W. En balance suma=1.
Con medidas inconsistentes no se fuerza artificialmente el complemento a
1-CW. measuredCrossweightActualSumFraction usa la suma REAL de mediciones,
con nombre diferente. 50% CW no implica 50% delantero. kg_equivalent se
convierte usando la gravedad de este vehículo, no un 9.81 fijo.

Load case identity incluye vehículo, configuración, modo, inputs y supuestos.
Load result conserva case completo e identity, familias/loads/residual/support,
provenance y tiempo. Validadores reconstruyen todo (excepto tiempo finito
no negativo) y rechazan alteraciones o fuentes de otro escenario.

## Equilibrio local: búsqueda y selección

Consumir SpringDamperSweepAnalysis validado y en reposo. Demanda explícita,
no negativa en N; el llamador puede usar loads.supportForce_N sólo si es finita.
Indeterminación o unsprung desconocido NO generan demanda por defecto.
F_w=F_s*MR, MR firmado. Resolver F_w(z)=support_target. No usa Fs/abs(MR).
Damping estático=0 y preload pertenece a la curva, no a la carga externa.

Búsqueda sin nuevos solves: muestras en orden, raíces de muestras y cruces de
segmentos lineales adyacentes válidos. Conserva creciente/decreciente sin
reordenar fuentes. Intervalo admisible recorta segmentos; nunca extrapola.
No interpola gaps, NOT_ATTEMPTED, force/MR no disponible, límites excedidos
ni cambio de branch de muelle. Datos originalmente válidos no garantizan
una rama oculta continua entre samples: estudiar convergencia de la malla.

Crossing: a=(demand-F_i)/(F_j-F_i), z_eq=z_i+a*(z_j-z_i).
Status PATH_INTERPOLATED_EQUILIBRIUM, no raíz exacta continua.
At sample: PATH_SAMPLE_EQUILIBRIUM, residual dentro del presupuesto numérico.
Todos los cruces RESOLUBLES POR ESTA MALLA se conservan. No puede descubrir
raíces dobles o tangencias interiores no muestreadas, ni dos cruces dentro
de un segmento con extremos de igual signo. rootCompleteness=SAMPLED_PATH_ONLY.

Flat interval exige matching endpoints y tangentes conocidas marginales
(o branch unseated: fuerza cero). Dos extremos iguales con tangentes no
nulas/desconocidas se guardan como matchingEndpointUnresolvedIntervals,
NO como prueba de plateau físico. Tampoco la malla demuestra una función
plana continua entre endpoints; requiere validación/convergencia independiente.

El filtrado de roots dentro de flats ordena una copia de intervalos por su
extremo inferior y recorre roots ya ordenadas. Un cursor sólo avanza y conserva
el máximo extremo superior de intervalos iniciados: coste O(F log F+R+F), memoria
O(F+R), extremos inclusivos. flatIntervals_m original no se fusiona ni reordena,
por lo que gaps y orden creciente/decreciente siguen visibles. Deduplicación
conserva la misma resolución de travel, calculada una sola vez para todo el path.
flatIntervalFilterDiagnostics registra R comparaciones y como máximo F avances;
los tests comprueban estructura, no ratios de tiempo dependientes del hardware.

Resultado: UNIQUE_LOCAL_EQUILIBRIUM, MULTIPLE_LOCAL_EQUILIBRIA,
FLAT_EQUILIBRIUM_INTERVAL, NO_EQUILIBRIUM_IN_VALID_TRAVEL o
INSUFFICIENT_VALID_PATH. Default UNIQUE_ONLY sólo selecciona una root aislada
única y sin flat interval; nunca elige la primera estable. NEAREST_REFERENCE
requiere referenceTravel_m explícito, incluso puede escoger una no restauradora.
Empate exacto: AMBIGUOUS_REFERENCE_SELECTION, sin selección. No selección:
travel/selectedRoot numéricos NaN. No hay globalChassisEquilibriumSolved=true.

## Root reporting, estabilidad y precisión

Cada root publica bracket/alpha, travel, springCompression/force, damperLength,
MR, soporte interpolado, residual, tangent rate completo y statuses de límites.
Valores entre samples son interpolaciones de REPORTING de cada curva,
no una pose resuelta; interpolación de Fs y MR por separado NO garantiza que
su producto sea igual a la interpolación de Fs*MR. El residual pertenece a
la fuerza interpolada, no se afirma residual de la ley continua re-resuelta.

Wheel rate usa sólo el total completo validado v0.8 (interpolado si interior).
K>threshold: LOCAL_RESTORING; K<-threshold: LOCAL_NON_RESTORING;
cerca de cero: LOCAL_MARGINAL_OR_DEGENERATE. No estabilidad global.
Con c2 F-01 no disponible se conserva root basada en fuerza/MR pero
K=NaN, STABILITY_NOT_EVALUABLE; nunca se sustituye por k*MR^2 o secante.
stabilityMethod distingue sample e interpolación. UNKNOWN bounds no son SAFE.

Options: travelInterval_m, forceAbsoluteTolerance_N=1e-8,
forceRelativeTolerance=1e-10, stiffnessZeroTolerance_N_per_m=1e-8*k,
rootSelection=UNIQUE_ONLY, referenceTravel_m=NaN, demandSourceKind/sourceNote.
Presupuesto residual: absTol+relTol*max(demand,1 N). Threshold de K es escala
numérica del modelo, no un umbral físico de estabilidad global; configurable.
Root identity se expresa en fuentes/modelIdentity/cornerId/demand/options
canónicos. El validador reconstruye método, raíces, reporting, residual,
stiffness, selección y status, no confía en CONVERGED publicado.

Error de samples (proxy): E_Fs=k*eC; E_Fw=abs(Fs)*E_MR+abs(MR)*E_Fs+E_Fs*E_MR
usando diagnostics F-01. Proxy de interpolación:
E_interp=max(abs(K_endpoint-secant))*abs(deltaZ)/4.
El factor 1/4 reproduce el error máximo del interpolante lineal para una
fuerza cuadrática con curvatura constante. NO acota una fuerza general:
endpoints no limitan extrema interiores de su derivada.
Travel proxy=E_interp/abs(secant). Con rate no disponible: NaN y
ACCURACY_UNQUANTIFIED. De otro modo HEURISTIC_ERROR_PROXY_NOT_A_BOUND.
No incertidumbre experimental/estadística ni garantía de error continuo.

## Escenarios, persistencia y futuro

Cada configuración de masa es otro VehicleParameters con identidad propia.
No suma piloto/fuel silenciosamente a un total operativo que ya los incluya.
Comparación B-A conserva NaN donde faltan datos y no infiere handling.
MAT de structs completos; validar tras load. No base de datos/JSON/servidor.
No se modifica ningún schema histórico ni solver; model/analysis mantienen
dependencias acíclicas, UI separada. No se llena fsd.vehicle con duplicados.

Futuro: Coupled Chassis Pose & Global Static Equilibrium, con heave/pitch/roll,
geometría 3D de cuatro suspensiones, contactos, balances sprung/unsprung,
carretera y tire vertical compliance cuando se especifique. ARB conserva
INTEGRATED/POST_DESIGN/DISABLED; anti-dive, anti-lift/anti-rise, anti-squat
siguen pendientes. No se inicia v0.10.

OPEN DECISION para futuro: modelo experimental de error de medidas,
refinamiento continuo de raíces con solves explícitos, política de selección
global, contacto/altura de chasis y fuerzas del modelo acoplado. No se fijan
hipótesis físicas adicionales para esas capacidades en v0.9.
