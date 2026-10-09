# v0.10 — Coupled Chassis Pose & Global Static Equilibrium

Modelo estático reducido de siete coordenadas; no sustituye a Adams ni valida
un vehículo fabricable. Todas las hipótesis ideales siguientes son explícitas.

## APIs y preparación

```matlab
tire = fsd.model.createVerticalTireModel(definition, units);
system = fsd.model.createGlobalStaticSystem(vehicle, loadCase, sources, tires, options);
prepared = fsd.analysis.prepareGlobalStaticSystem(system);
state = fsd.analysis.evaluateGlobalStaticState(system, q);
result = fsd.analysis.solveGlobalStaticEquilibrium(system, initialGuesses, solverOptions);
fsd.analysis.validateGlobalStaticState(state, system);
fsd.analysis.validateGlobalStaticEquilibrium(result, system);
figures = fsd.analysis.plotGlobalStaticEquilibrium(system, result);
performance = fsd.analysis.benchmarkGlobalStaticEquilibrium(system, q, solverOptions);
```

`sources`/`tires`: cuatro cells FL/FR/RL/RR. Cada source contiene geometry,
actuation, springDamper, mechanical, pathKind. Modelos asociados por identities
exactas; mechanical es un análisis v0.8 completo en reposo. Schemas antiguos
intactos. El aggregate en model no depende de analysis/kinematics.
Preparación downstream valida fuentes y construye interpolantes antes del loop.
Prepared es un struct serializable para inspección, no un token mutable de confianza.
Cada API pública de evaluación/solve recibe el sistema original y lo prepara;
evaluaciones internas de solver/plots/benchmark reutilizan el prepared privado.
El core energético no ejecuta factories, validators, análisis de sweeps ni solves
de double wishbone/steering/rocker. No se omite validación para ganar velocidad.

Producción `ACTUATION_BUMP_3D`: consume ActuationSweep de BumpSweep validado con
inboard fijo (rack cero); WC procede del KinematicResult REAL. No se sustituye
su migración XY por una línea vertical. Rama de rocker por signo de la derivada
del closure; tangencias/ill-conditioning se excluyen. El sweep v0.8 no define
un path de steering a rack no nulo fijo: aquí se rechaza, sin mezclar rack sweeps.

Fixture `IDEAL_PRESCRIBED_3D`: PrescribedDamperPath v0.8 más matriz explícita N×3
idealWheelCenterPath_m, sourceKind=ASSUMED y sourceNote obligatorio. Debe cumplir
WC.Z=WCnominal.Z+z; permite XY prescrito sin declarar feasibility del mecanismo.
Nunca fabrica KinematicResult/ActuationResult. No sirve para omitir la validación
de una fuente de producción fallida.

## Pose, marco y unidades

Se conservan X atrás, Y derecha, Z arriba, origen nominal entre contactos delanteros.
Izquierda Y negativa; derecha positiva. Todas las posiciones internas en m,
ángulos rad, masas kg, fuerzas N, momentos Nm, energía J.

```text
q = [h, theta, phi, zFL, zFR, zRL, zRR]' [m,rad,rad,m,m,m,m]
R = Rx(phi)*Ry(theta)
pWorld = R*pBody + [0,0,h]'
```

theta mano derecha +Y: frente (-X respecto al origen de rotación) sube;
phi mano derecha +X: derecha sube. R finita, orden no conmutativo, yaw y
translation XY fijos. |theta|,|phi|<pi/2 define la carta, no límites físicos.
El mismo R transforma WC, sprung CG y referencias; hardpoints de chasis
usan esta misma transformación. El plot representa un polígono de referencia,
no inventa el fondo del monocoque.
z es wheel travel body-relative, h traslación del origen: no son ride height.
Sólo se publican alturas de rideHeightPointsBody_m/rideHeightPointIds explícitos.
Sin referencias se devuelven arrays vacíos. Road: un plano horizontal rígido
Z=roadHeight_m, default 0; no cuatro alturas independientes o pendiente.

## Neumático opcional y unilateral

Definition exige cornerId, modelType=LINEAR_VERTICAL_UNILATERAL, stiffness,
unloadedRadius, sourceKind KNOWN/ASSUMED/FIXED/DERIVED y sourceNote. No defaults
para kt/R0. Units length=m/mm y stiffness=N/m o N/mm, convertidos en factory.

```text
d = roadZ-(WCworld.Z-R0)
delta=max(0,d); gap=max(0,-d)
N=kt*delta >= 0; Ut=0.5*kt*delta^2
Rloaded=R0-delta
```

Rloaded no es radio dinámico de rodadura; Rloaded<=0 se considera inválido.
No es CONTACT_PATCH material histórico ni contacto circular camber-dependent.
La fuerza vertical actúa con la XY del WC (mismo momento en suelo/WC).
Sin tire damping, presión, slip o fricción. `verticalTireResponse` aísla la ley
para sustituirla mediante otro tipo/contrato aprobado, sin alterar el resto
de gravedad/muelles.

d==0: CONTACT_TRANSITION. 0<|d|<=16*eps(max(|roadZ|,|WC.Z|,R0,1 m)):
CONTACT_NUMERICALLY_UNRESOLVED; fuera IN_CONTACT/AIRBORNE según signo.
16 ulps es presupuesto aritmético, no clearance de ingeniería. No se recorta
una normal positiva pequeña: max usa d original. Unresolved no permite
certificar equilibrio; transición exacta puede ser estacionaria, sin Hessiano
bilateral. Airborne tiene N=Ut=0 y gap positivo, nunca tensión.

## Masas y CG móviles

Se reutiliza VehicleParameters/VehicleLoadCase v0.9 con M/g/CG nominal XYZ
explícitos. Cuatro mu conocidas o ZERO_UNSPRUNG_APPROXIMATION explícita,
registrada en identity, preservando datos originales. NaN no implica cero.
Ms=M-sum(mu)>0. Hipótesis UNSPRUNG_MASS_AT_WHEEL_CENTER:

```text
rCGsBody=(M*rCGtotalNominal-sum(mu_i*WCnominalBody_i))/Ms
CGsWorld=R*rCGsBody+[0,0,h]'
CGuWorld_i=WCworld_i(zi,q)
CGtotalWorld=(Ms*CGsWorld+sum(mu_i*WCworld_i))/M
Ug=Ms*g*ZCGsWorld+sum(mu_i*g*ZWCworld_i)
```

Unsprung está incluida en M, no se vuelve a sumar. El CG total nominal no es
un punto rígido si incluye masas móviles. Concentrarlas en WC es un modelo
reducido explícito, no el CG real de todos los links/componentes.

## Energía, residuales y momentos

Se reutilizan springLaw/mechanicalBounds v0.8, sin segunda ley de muelle.
Ldamper=L0-c(z), asientos=Ldamper+offset v0.8; Fs=k*max(preload+c,0),
Us=.5*k*max(preload+c,0)^2, MR=dc/dz firmado. Damper viscoso a velocidad cero,
fuerza cero. No gas/stiction/stop reactions. Exceedance/seat geometry imposible
invalidan U/residual, sin prolongar la ley. UNKNOWN no significa SAFE.

```text
U=Ug+sum(Us)+sum(Ut)
residual=gradient_q(U)
Rh=M*g-sum(N)
Rzi=Fs_i*MR_i+(mu_i*g-N_i)*eZ'*R*pWCbody_i'(zi)
```

No se supone WC vertical en world. A theta=phi=0 y WCbody.Z'=1 se obtiene
FsMR+mu*g-N. Gradiente/Hessiano candidato usan los MISMOS pp de WC y c;
nunca Fs y MR interpolados por separado. Derivadas de R finitas analíticas.
Balance independiente en world, fuerzas físicas arriba positivas:

```text
Fz=sum(N)-M*g
Mx=sum(YWC_i*(N_i-mu_i*g))-Ms*g*YCGs
My=-sum(XWC_i*(N_i-mu_i*g))+Ms*g*XCGs
Mz=0 (fuerzas verticales solamente)
Rphi=-Mx; Rtheta=-cos(phi)*My
```

Eje instantáneo de theta=Rx(phi)*eY: el factor cos(phi) es necesario. Se
comprueban Mx/My con coordenadas actuales, no sólo residuales angulares.
State publica Ug/Us/Ut/U separados, CGs/CGtotal actuales y normales/cargas.

## Paths, interpolación y F-01

PCHIP por componente en segmentos de >=3 muestras. Orden original monótono;
sólo una copia de un segmento descendente ya comprobado se invierte.
Se cortan failed/NOT_ATTEMPTED, MR indisponible, spacing irresoluble,
ill-conditioned, límites excedidos, duplicados, cambios de sentido o rama.
No extrapolación ni salto Newton a otro segmento desconectado.
Queries interiores conservan SOURCE_FAILURE_PATH_GAP, MECHANICAL_LIMIT_PATH_GAP
o status de MR upstream; OUTSIDE_SAMPLED_PATH identifica fuera del dominio,
no se confunde con una fuente fallida.
Derivada del pp con unmkpp/mkpp, sin Toolbox nuevo. PCHIP conserva forma y es C1; su c2
puede saltar en knots ([MathWorks](https://www.mathworks.com/help/matlab/ref/pchip.html)).
Las APIs usadas se verifican en R2025b, no se depende de R2026.

MR del pp se compara con MR upstream interpolado linealmente; diferencia
>1e-6+1e-3*abs(MRsource) produce INTERPOLATED_MR_DISAGREEMENT. El presupuesto
1 ppm/0.1% reutiliza F01-1 numérico, no tolerancia de ingeniería. Diferencias
en samples se conservan en prepared. Refinamiento de malla es explícito,
no resuelve mecanismos ocultamente.

Hessiano certificable sólo si muestras del tramo pasan c2 F-01, MR válido,
sin transición/unresolved/coil-bind boundary, y lejos de extremos del dominio.
En knots se compara c2 izquierda/derecha por componente con presupuesto
1e-6+1e-3*max(abs(left),abs(right)), unidades canónicas de cada componente
(WC/c en m derivados respecto a m). Un salto irresoluble suprime estabilidad.
candidateHessian es diagnóstico si bilateralHessianAvailable=false.
Gates no acotan truncación/error de geometría continua. Todos los outputs
llevan SAMPLED_PATH_APPROXIMATION; hace falta convergencia de malla real.

## Solver, selección y estabilidad

Newton amortiguado determinista sobre 7 residuales, no minimización que oculte
roots no restauradoras. Caja bounds 7×2 y coordinateScales 7×1 explícitas.
forceTolerance_N, momentTolerance_Nm, positionTolerance_m, angleTolerance_rad,
stabilityTolerance_J positivas obligatorias. Sin valores típicos FS presumidos.
Defaults algorítmicos: 80 iteraciones, 30 pasos line search, rcond threshold
sqrt(eps), UNIQUE_ONLY. No nuevo Toolbox; Optimization Toolbox histórico se
necesita para generar paths reales, no para este solve reducido.

Jacobian de gradient con diferencias centrales eps^(1/3)*scale, unilaterales
si un lado no está disponible. No usa c2 F-01 inválido para buscar fuerzas.
Resuelve J escalado o pseudoinversa si mal condicionado, con diagnóstico.
Line search por mitades: mejora estricta del máximo residual/budget, factible
y mismo segmento. Paso pequeño sin residual aceptable no converge.
Fallos/max iterations/stagnation se conservan. Una caja no es un tope mecánico.
Root a position/angleTolerance del borde artificial no se certifica.

Aceptación reconstruida: 7 residuales dimensionales, Fz/Mx/My world, identidades,
dominios, no exceder límites y contacto no unresolved. No exige cuatro normales
positivas: wheel lift puede ser equilibrio. Boundary coil bind/engagement no
permite estabilidad bilateral, aunque exista fuerza pre-limit.

InitialGuesses 7×N; se conservan attempts y todas las roots válidas encontradas,
deduplicadas con position/angleTolerance. rootCompleteness=SUPPLIED_SEEDS_ONLY.
UNIQUE_ONLY elige sólo una alternativa encontrada, sin afirmar unicidad global.
LOWEST_ENERGY_STABLE elige menor U entre mínimos locales certificados;
empate exacto o ninguna candidata estable deja selectedIndex=NaN.
Una alternativa única no restauradora sigue siendo root, no un setup estable.

F-01 v0.10: el filtro LOCAL_STABLE_MINIMUM se aplica igual con cero, una o
varias alternativas. NON_RESTORING_STATIONARY_POINT, MARGINAL_OR_DEGENERATE y
STABILITY_NOT_EVALUABLE se conservan como diagnósticos, pero no son elegibles.
Todas las energías elegibles deben ser escalares reales finitos; si alguna
no es válida, no puede certificarse el mínimo del conjunto y no se selecciona.
El validator público reconstruye la física, que ya exige energía válida.
No se introduce tolerancia de empate: valores exactamente iguales dejan NaN;
valores distintos, aunque muy próximos, se comparan literalmente. Índices
siguen el orden de roots encontradas; la configuración de menor U no depende
del orden de seeds (salvo el representante equivalente de deduplicación).
No se promete mínimo global ni completitud de búsqueda.

status cuenta roots: UNIQUE_FOUND_EQUILIBRIUM puede coexistir con NaN bajo
LOWEST_ENERGY_STABLE. Ausencia de selección no implica ausencia de raíces.
UNIQUE_ONLY conserva su semántica: selecciona una root única aun no estable.
Los consumidores comprueban selectedIndex antes de indexar: sin selección
no se publica pose/cargas seleccionadas; el plot rechaza antes de crear figuras,
el ejemplo informa la política sin selección y MAT conserva alternativas/NaN.

Hessiano de energía escalado D*H*D, D=diag(scales), eigenvalores en J.
Todos >stabilityTolerance_J: LOCAL_STABLE_MINIMUM; alguno <-umbral:
NON_RESTORING_STATIONARY_POINT; resto MARGINAL_OR_DEGENERATE. Sin gates fiables:
STABILITY_NOT_EVALUABLE. Es estabilidad local DEL MODELO, no ensayo físico,
ni se infiere de cuatro wheel rates. DOF libre/J singular se informa.

## Resultados, identity e integridad

State siempre EVALUATED_NOT_SOLVED. Solution añade aceptación/estabilidad/rcond;
Result conserva attempts, alternativas, selección y opciones. Sin selección
NaN, no copia de nominal. Corners: z/WC world, c/Ldamper, spring Fs/FsMR/energy/
gap, MR/difference, limits, tire R0/Rloaded/delta/gap/N/contact/energy.
CWpred=(FR+RL)/sum(N), salida emergente, no cuarta ecuación impuesta.
comparisonV09 conserva referencia nominal/medidas/CW/familia y diferencias;
indeterminados siguen NaN. CW v0.9 con M*g y CW de suma real mantienen nombres
distintos. La pose/migración puede cambiar el reparto de referencia; nunca
se ajustan mediciones. Metadata/tiempos no son física reconstruida.

Identity sin hash incluye vehículo/case, modelos físicos, geometry/actuation,
tire kt/R0, path/calidad, road/masa/hipótesis/orden R/referencias físicas;
metadata/display names excluidos. Fuentes se validan íntegramente downstream.
Validator reconstruye coordenadas, fuerzas, U, residuales, contactos/límites,
aceptación, Hessiano/estabilidad y selección. No confía en flags almacenados;
contadores/tiempos no autentican la historia de ejecución.

## Referencias independientes, rendimiento y límites

Benchmark: M200, g10, MR.5, ks20000, preload.05, kt100000, R0.25,
CG[1,0,.3], mu0 explícitas. h=-.005, theta=phi=z_i=0; N_i500, Fs1000,
FsMR500, delta.005; Ug590, Us100, Ut5, U695 J.
Compliance: 1/keff=1/(ks*MR²)+1/kt. Tests usan también gradient de U por
diferencias independientes, rotaciones finitas, pitch/roll CG, preload/CW y mu.

Tres apoyos ideales: FL c=-.5z/preload0 descargado, resto c=.5z/preload.05;
CG[4/3,.65/3,.3], h=-.04, zFL=.048, restantes1/30; N=[0,2000/3,2000/3,2000/3],
gap FL .008 y DOF libre: marginal, no mínimo estricto.
Múltiple c=.5z-10z²: FsMR=500 tiene z0 y (.075-sqrt(.020625))/2 en dominio.
Roots del pp se contrastan con referencia continua con tolerancia de interpolación.

Benchmark de tiempos: warm-up y mediana de tres evaluaciones; preparación,
validación fuentes, pp, evaluación total, ensamblado U, ensamblado gradient+H,
solve y validación resultado separados. Ensamblados no incluyen geometría/leyes
comunes ni son APIs independientes. Counters de residual/iterations son del
loop Newton; aceptación/validación agregan otras evaluaciones fuera del loop.
Perfil energético independiente verifica cero validators/factories/solves.
Sin metas arbitrarias de velocidad; mediciones locales, no garantías.

OPEN DECISION para uso real: kt/R0 medidos, CG unsprung real, convergencia de
malla/error experimental, selección física entre ramas y contrato fixed-rack
no nulo. Sin dinámica/yaw/aero/aceleración, ARB/anti geometry, optimización,
rules/Tilt/UI/Adams, third springs ni stop/hysteresis laws. Se conserva ARB
INTEGRATED/POST_DESIGN/DISABLED y anti-dive/lift/rise/squat futuros.
