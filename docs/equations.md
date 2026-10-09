# Convenciones y formulación matemática

## Equilibrio global v0.10

R=Rx(phi)*Ry(theta), WCworld=R*WCbody(z)+[0,0,h].
Ms=M-sum(mu); CGsBody=(M*CGnominal-sum(mu*WCnominal))/Ms.
Ug=Ms*g*ZCGsWorld+sum(mu*g*ZWCworld), Us=.5*k*max(preload+c(z),0)^2.
d=roadZ-WCworld.Z+R0; delta=max(0,d); N=kt*delta; Ut=.5*kt*delta².
U=Ug+sum(Us)+sum(Ut); residual=gradient_q(U).
Rh=M*g-sum(N); Rzi=Fs*dc/dzi+(mu*g-N)*eZ'*R*dWCbody/dzi.
Mx=sum(YWC*(N-mu*g))-Ms*g*YCGs;
My=-sum(XWC*(N-mu*g))+Ms*g*XCGs; Rphi=-Mx; Rtheta=-cos(phi)*My.
Derivadas y energía provienen del mismo pp, no de fuerza/MR independientes.
Hessiano global escalado y gates F-01/contact/knots, unidades, signos,
tolerancias y derivación finita en [especificación v0.10](global-static-equilibrium.md).
No se añade física a las fórmulas históricas siguientes.

## Body-roll closure v0.6

Para `phi` finito con `abs(phi)<pi/2`, la carretera horizontal del mundo se
expresa en YZ del chasis mediante:

```text
dRoad = [cos(phi), -sin(phi)]
nRoad = [sin(phi),  cos(phi)]
dRoad dot nRoad = 0
```

Con contactos geométricos actuales `CL` y `CR`, el cierre es:

```text
F(Delta) = nRoad dot (CR(Delta)-CL(Delta)) = 0
zLeft  = h + Delta
zRight = h - Delta
h = (zLeft+zRight)/2
```

Se evalúan los contactos del mecanismo resuelto; no se sustituye este problema
por `Delta=(track/2)*tan(phi)`. `fzero` usa un bracket expandido alrededor del
Delta del paso anterior. La trayectoria canónica lleva primero `h:0->target`
con `phi=0` y después `phi:0->target` manteniendo h.

El bracket se construye solo con muestras cinemáticamente válidas. Centro,
lado negativo y lado positivo se evalúan independientemente; después se buscan
cambios de signo entre muestras válidas adyacentes. Si una expansión cruza el
límite alcanzable de un lado, se biseca entre su última muestra válida y la
primera inválida, mientras el otro lado puede seguir expandiéndose. Un extremo
inválido no descarta un bracket `center↔endpoint` válido del lado opuesto.

Si hay varios brackets, se elige determinísticamente el más próximo al Delta
anterior: primero distancia del intervalo al estado previo, después distancia
de su punto medio, anchura y extremo inferior. El solver busca únicamente la
raíz alcanzable localmente conectada a la rama de continuation. No garantiza
encontrar todas las raíces; bifurcaciones, múltiples soluciones o
singularidades pueden producir selección de otra rama o fallo conservador.

La road line normalizada es `aY+bZ+c=0`, con `sqrt(a^2+b^2)=1`, `b>0` y
`[a,b]=nRoad`. Para RC finito:

```text
rollCenterRoadHeight = a*Y_RC + b*Z_RC + c
```

El frame alineado con carretera se obtiene con `Rx(+phi)` aplicado a vectores
del chasis. El road-relative camber es la ecuación histórica de camber aplicada
al wheel axis transformado.

### Benchmark analítico de traslación

La fixture v0.6 usa brazos paralelos de radio `r=0.30 m`, wheel axis constante
y contacto estático a semitrack `T/2=0.65 m`. Para `h=0`, sea
`A=T/2-r=0.35 m` y `t=tan(phi)`. La rama continua desde cero cumple exactamente:

```text
Delta = t*(A + sqrt(r^2 + t^2*(r^2-A^2))) / (1+t^2)
```

Este expected procede del arco circular y del plano de carretera, no del
solver bajo test.

## Sistema y unidades

El marco global es diestro: X hacia atrás, Y hacia la derecha y Z hacia arriba. Posiciones y wheel travel se almacenan en metros; rotaciones y métricas angulares, en radianes.

Para dos puntos:

```text
v_AB = p_B - p_A
d(A,B) = norm(v_AB, 2)
u_AB = v_AB / norm(v_AB, 2)
```

## Wheel travel v0.2

```text
wheelTravel = Z_WC,current - Z_WC,static
```

- `wheelTravel > 0`: bump/jounce.
- `wheelTravel < 0`: rebound/droop.
- `wheelTravel = 0`: configuración estática.

No representa damper travel, movimiento de ball joints ni heave del vehículo.

## Cierre físico del mecanismo

La pose del upright no queda determinada solo por UBJ y LBJ: esos puntos permiten una rotación libre alrededor de su línea. v0.2 añade `TIE_ROD_INBOARD` fijo al chasis y `TIE_ROD_OUTBOARD` rígidamente unido al upright. Con steering input fijo, la longitud del tie rod es constante y elimina ese grado de libertad.

Los pivotes interiores UCA/LCA permanecen fijos. En bump aislado,
`TIE_ROD_INBOARD` también permanece fijo; en steering v0.5 su posición es un
input prescrito por el rack. El upright rígido contiene UBJ, LBJ,
`TIE_ROD_OUTBOARD`, Wheel Center, Contact Patch y wheel axis.

## Variables del solver

Sea `c0` el Wheel Center estático y `w` el wheel travel solicitado. Se emplean cinco incógnitas:

```text
q = [deltaX, deltaY, rhoX, rhoY, rhoZ]
```

`rho` es un rotation vector: su dirección es el eje de rotación y su norma el ángulo en radianes. No se usan Euler angles.

La traslación del Wheel Center es:

```text
t = [deltaX, deltaY, w]
```

Para cualquier punto estático `p0` solidario al upright:

```text
p(q,w) = c0 + t + R(rho) * (p0 - c0)
```

El wheel axis solo rota:

```text
a(q) = R(rho) * a0
```

Esta parametrización conserva exactamente todas las distancias internas del upright y las relaciones rígidas de Wheel Center, Contact Patch y wheel axis. Por construcción, `Z_WC,current = Z_WC,static + w`.

## Rotation vector

Con `K = skew(rho)` y `theta = norm(rho)`:

```text
R = I + sin(theta)/theta * K
      + (1-cos(theta))/theta^2 * K^2
```

Cerca de cero se usan las series de Taylor de ambos coeficientes para evitar cancelación numérica. La matriz resultante satisface `R'*R = I` y `det(R)=+1` dentro de precisión numérica.

## Cinco restricciones

La rigidez del upright ya está incorporada en la parametrización. Solo se resuelven las cinco longitudes que lo unen al chasis:

```text
|UCA_FWD_CHASSIS - UBJ(q,w)| = L_UCA_FWD
|UCA_AFT_CHASSIS - UBJ(q,w)| = L_UCA_AFT
|LCA_FWD_CHASSIS - LBJ(q,w)| = L_LCA_FWD
|LCA_AFT_CHASSIS - LBJ(q,w)| = L_LCA_AFT
|TIE_ROD_INBOARD - TIE_ROD_OUTBOARD(q,w)| = L_TIE_ROD
```

Cada residual se escala por su longitud estática:

```text
r_i = (L_i,current - L_i,static) / L_i,static
```

Así se obtiene un sistema cuadrado de cinco ecuaciones y cinco incógnitas, sin coordenadas libres redundantes ni constraints internas duplicadas.

## Solver y continuación

Se utiliza `fsolve` de Optimization Toolbox con algoritmo trust-region-dogleg. La solución estática exacta es `q=0`.

Para un target no nulo se avanza desde la última solución convergida mediante pasos internos de wheel travel de tamaño máximo configurable, por defecto `5 mm`. Cada solución es el initial guess del paso siguiente. Un sweep conserva la continuación entre targets consecutivos. Esta estrategia selecciona la rama conectada continuamente con la geometría estática; no selecciona una raíz arbitraria.

Una solución solo se acepta cuando `fsolve` informa convergencia y el error dimensional máximo de las cinco longitudes cumple las tolerancias numéricas del proyecto. Un fallo devuelve `converged=false` y no expone una pose como si fuera válida.

## Rack y cierre combinado v0.5

Sean los inner joints estáticos `P_L` y `P_R`. El rack unitario y las
posiciones actuales son:

```text
u_rack = (P_R-P_L) / norm(P_R-P_L)
P_L(q) = P_L + q*u_rack
P_R(q) = P_R + q*u_rack
```

Ambos puntos tienen la misma traslación, su separación permanece constante y
el rack no rota. No se exige `u_rack=[0,1,0]`.

El núcleo generalizado resuelve exactamente las cinco restricciones anteriores
sustituyendo la última por:

```text
|P_tie,inboard,prescribed - TIE_ROD_OUTBOARD(q_pose,w)| = L_TIE_ROD
```

`solveBump` prescribe el inboard estático y mantiene su API histórica. Para
steering, la continuation determinista es: (1) desde `[wheelTravel=0,rack=0]`
hasta el wheel travel objetivo con rack cero; (2) mantener ese wheel travel y
avanzar el rack hasta el target. El tamaño de paso se limita usando el máximo
entre incremento absoluto de wheel travel y norma de la traslación del inner
joint.

## Road-wheel heading y ángulos

Para wheel axis unitario `a=[a_x,a_y,a_z]` interior→exterior y
`s=sideSign`, se proyecta primero al plano horizontal y se normaliza como
`b=[a_x,a_y,0]/norm([a_x,a_y])`. Rotarla 90 grados y escoger el sentido
delantero produce:

```text
h = s * [-b_y, b_x, 0]
roadWheelAngle = atan2(h_y, -h_x)
```

Con rueda recta, `a=[0,s,0]` y `h=[-1,0,0]`. Por tanto, ángulo positivo
apunta a `+Y`. Las diferencias angulares usan siempre:

```text
wrap(delta) = atan2(sin(delta), cos(delta))
steerDeflectionFromStatic = wrap(psi_current-psi_static)
rackInducedSteer = wrap(psi(w,q)-psi(w,0))
```

Toe conserva su definición v0.3 independiente; no se sustituye por estos
ángulos.

## Intersección del steering axis con el plano horizontal

Con `k=UBJ-LBJ` y plano `Z=z_road`, la recta es `LBJ+t*k`. Si `k_z` es no
nulo:

```text
t = (z_road-LBJ_z)/k_z
S = LBJ+t*k
conditioning = abs(k_z/norm(k))
```

Si el eje es degenerado se publica `DEGENERATE`; si es paralelo o
numéricamente indistinguible del plano, `PARALLEL`. Una solución finita puede
marcarse ill-conditioned sin inventar un punto distante.

## Scrub radius y mechanical trail

Para contacto geométrico actual `C`, intersección `S` y `s=sideSign`:

```text
scrubRadius = s*(C_y-S_y)
mechanicalTrail = C_x-S_x
```

Scrub positivo significa que el contacto está más outboard. Con X positivo
hacia atrás, trail positivo significa que `S` está por delante de `C`. Ambos
usan el steering axis y contacto actuales en bump, rebound o steering. Trail
es exclusivamente mecánico, no neumático.

## Ackermann por ICR geométrico

La referencia mínima del eje trasero es `I_x=rearAxleX`. Para cada contacto
`C` y heading horizontal `h`, el ICR sobre esa línea satisface
`h dot (I-C)=0`, luego:

```text
I_y = C_y - h_x*(rearAxleX-C_x)/h_y
```

Una forma proyectiva unidimensional equivalente, usada para razonar sin
forzar la división, es:

```text
[numerator, denominator]
numerator   = h_y*C_y - h_x*(rearAxleX-C_x)
denominator = h_y
```

Si `h_y` es casi cero, el ICR es `INFINITE`; sus coordenadas euclídeas son
`NaN`. `conditioning=abs(h_y)` para un heading unitario. Esto evita presentar
una distancia enorme como un ICR fiable cerca de recto.

Para un giro definido por `rackInducedSteer`, FR es inner en giro derecho y
FL en giro izquierdo. Se toma el ICR de la rueda inner y se construye para el
contacto exterior real —incluido wheel stagger— el heading tangente al radio
contacto–ICR y orientado hacia `-X`. El error adoptado es:

```text
ackermannAngleError = wrap(actualOuterAngle-idealOuterAngle)
icrMismatch = ICR_left_y-ICR_right_y
```

No se define porcentaje Ackermann. En rack cero/steering despreciable se
publica `NEAR_STRAIGHT`; el toe estático por sí solo no convierte ese estado
en un turn válido.

## Camber

El wheel axis unitario `a=[a_x,a_y,a_z]` apunta siempre interior→exterior. Se define:

```text
s = -1  para FL/RL
s = +1  para FR/RR
a_out = s * a_y
camber = -atan2(a_z, a_out)
```

`a_out` es la componente lateral hacia el exterior. La proyección del eje sobre el plano lateral-vertical hace que la expresión sea independiente del signo global Y de cada lado:

- `a_z > 0` implica que la parte superior de la rueda se inclina hacia el centro: camber negativo;
- `a_z < 0` implica inclinación superior hacia fuera: camber positivo;
- una geometría reflejada conserva `a_z` y cambia simultáneamente `s` y `a_y`, por lo que conserva el signo y valor de camber.

Camber se devuelve en radianes. Toe no se calcula ni se publica en v0.2.

Desde v0.3, `fsd.geometry.camberFromWheelAxis` contiene la única implementación de la ecuación. `fsd.analysis.camberFromWheelAxis` aplica la validación estricta v0.3 y `fsd.kinematics.camberFromWheelAxis` permanece como wrapper compatible con v0.2.

## Toe

Sea `a=[a_x,a_y,a_z]` el wheel axis unitario interior→exterior y:

```text
s = -1  para FL/RL
s = +1  para FR/RR
a_out = s * a_y
toe = atan2(-a_x, a_out)
```

Se exige `a_out>0`. La fórmula usa únicamente la proyección XY: `a_z` no participa y, por tanto, camber por sí solo no produce toe ficticio.

Para un ángulo positivo `theta` de toe-in, el wheel axis horizontal ideal es:

```text
a_toe-in = [-sin(theta), s*cos(theta), 0]
```

Como X positivo apunta hacia atrás, la componente X del wheel axis exterior es negativa en toe-in para ambos lados. Sustituyendo en la ecuación se obtiene `toe=+theta`. Toe-out invierte `a_x` y produce `toe=-theta`.

## Steering axis

Con posiciones actuales de LBJ y UBJ:

```text
k = (p_UBJ - p_LBJ) / norm(p_UBJ - p_LBJ)
```

`k` apunta siempre de LBJ a UBJ. No se invierte para obtener `k_z>0`; un eje con proyección válida pero geometría no convencional conserva su orientación física.

## Caster

Caster usa la proyección XZ del steering axis:

```text
caster = atan2(k_x, k_z)
```

Es positivo si el extremo superior UBJ está desplazado hacia `+X`, es decir, hacia la parte trasera del vehículo. La reflexión lateral no cambia X ni Z, por lo que conserva caster.

## Kingpin inclination

La nomenclatura canónica es `kingpinInclination`; KPI se usa solo como abreviatura. Con `s` definido por lado:

```text
k_in = -s * k_y
kingpinInclination = atan2(k_in, k_z)
```

Es positivo cuando el extremo UBJ se inclina hacia el centro: `k_y>0` a la izquierda y `k_y<0` a la derecha. Al reflejar, cambian simultáneamente `s` y `k_y`, de modo que el valor se conserva.

## Bump steer

Para wheel travel `z`:

```text
bumpSteer(z) = toe(z) - toe(0)
```

`toe(0)` es el toe de la geometría estática canónica, no el primer punto del sweep. Si cero no está solicitado, tampoco se sustituye por el target más próximo a cero. Así se preservan separadamente el toe estático, el toe instantáneo y el cambio debido al movimiento. No se interpola sobre estados no convergidos.

## Reflexión lateral

```text
M_Y = diag([1, -1, 1])
p_mirror = M_Y * p
a_mirror = M_Y * a
```

La reflexión conserva X, Z y distancias, y cambia `FL↔FR` o `RL↔RR`. `det(M_Y)=-1`; no es una rotación propia.

## Restricción cinemática frontal de un wishbone v0.4

Sean `P1` y `P2` los pivotes interiores 3D y `B` el ball joint actual. El eje
interior unitario y la proyección ortogonal de `B` sobre él son:

```text
u = (P2-P1) / norm(P2-P1)
Paxis = P1 + dot(B-P1,u)*u
r = B-Paxis
```

La dirección instantánea de velocidad del ball joint al rotar el wishbone
alrededor de su eje es:

```text
v = u × r
q = [v_y, v_z]
```

La restricción cinemática en la vista matemática YZ es la línea que pasa por
la proyección del ball joint y es perpendicular a esa velocidad proyectada:

```text
v_y*(Y-B_y) + v_z*(Z-B_z) = 0
```

UCA usa UBJ y LCA usa LBJ. El orden de los dos pivotes puede invertir `u` y
`v`, pero no altera la línea después de su normalización canónica. No se usa
un midpoint ni un plano `X=constante`. Por ello la formulación sigue siendo
válida con ejes interiores oblicuos, ball joints longitudinalmente escalonados
y wheel stagger.

El contrato es `DEGENERATE` si los pivotes no definen un eje, el ball joint
está sobre ese eje o `norm(q)` es numéricamente nulo. Cuando el eje interior
es longitudinal, la restricción pasa por el YZ del pivote interior y el YZ del
ball joint, recuperando exactamente la construcción frontal clásica.

## Intersecciones proyectivas YZ y FVIC

Una línea euclídea normalizada se almacena homogéneamente como:

```text
l = [A,B,C]
A*Y + B*Z + C = 0
sqrt(A^2+B^2) = 1
```

Un punto finito es `p=[Y,Z,1]`; una dirección o punto en infinito es
`p=[dY,dZ,0]`. La unión de dos puntos y la intersección de dos líneas usan el
producto vectorial homogéneo:

```text
l = p1 × p2
p = l1 × l2
```

La intersección es `FINITE` cuando `p_3` es no nulo, `INFINITE` cuando
`p_3=0` y queda una dirección no nula, `COINCIDENT` cuando las líneas son la
misma, y `DEGENERATE` cuando algún dato no define una construcción única.
Solo `FINITE` publica Y/Z. `INFINITE` publica dirección unitaria y coordenadas
euclídeas `NaN`, no un punto artificialmente lejano.

Para normales unitarias, el indicador de condicionamiento es:

```text
conditioning = abs(A1*B2-B1*A2) = abs(sin(theta))
```

Un valor pequeño indica una intersección finita sensible. El flag
`isIllConditioned` informa esa condición sin cambiar un resultado finito por
uno infinito. El FVIC cinemático es `upperConstraint ∩ lowerConstraint`.

Por definición, el **Front-View Kinematic Instant Center** es la intersección
en YZ de las líneas que pasan por UBJ y LBJ proyectados y son normales a sus
respectivas velocidades instantáneas proyectadas, derivadas de la rotación de
cada wishbone alrededor de su eje interior real.

## Rueda circular rígida y contacto geométrico

El radio geométrico estático es:

```text
R = norm(CONTACT_PATCH_static - WHEEL_CENTER_static)
```

Para habilitar el análisis v0.4, el datum estático debe coincidir con el punto
más bajo del círculo ideal, pertenecer al plano perpendicular al wheel axis y
estar en `Z=0`. Esta es una precondición del análisis, no del schema histórico
`DoubleWishboneGeometry`.

Para centro actual `WC`, wheel axis unitario `a` y vertical descendente
`d=[0,0,-1]`:

```text
d_p = d - (d·a)*a
d_hat = d_p / norm(d_p)
C = WC + R*d_hat
```

`C` es el punto del círculo que minimiza Z. Si `norm(d_p)` es numéricamente
nulo —wheel axis vertical— el contacto no es único y se devuelve
`DEGENERATE`. Este modelo no es loaded radius, effective rolling radius ni un
modelo de fuerzas de neumático. El `CONTACT_PATCH` transformado rígidamente
permanece como datum material y no sustituye a `C`.

## Roll center del eje

Para cada lado se construye la línea geométrica YZ desde el contacto ideal
finito `C=[Y_C,Z_C,1]` hasta su FVIC homogéneo. Se denomina
`rollCenterConstructionLine`; no afirma que se haya calculado una fuerza de
neumático:

```text
constructionLine = C × IC
```

La misma operación funciona si el IC es `INFINITE`: produce la línea que pasa
por el contacto con la dirección del IC, sin elegir una distancia ficticia.

El roll center es la intersección de las dos líneas de construcción:

```text
RC = line(C_left, IC_left) ∩ line(C_right, IC_right)
```

No se impone `RC_Y=0`. Si las líneas se cortan en infinito, el roll center
queda `INFINITE` con dirección válida y `RC_Y/RC_Z=NaN`. Coincidencia y
degeneración también son explícitas. Dos IC infinitos pueden, no obstante,
generar líneas de construcción cuya intersección sea un roll center finito.

`rollCenterZ_m` es siempre coordenada global/chassis-frame. Si los dos
contactos comparten nivel dentro de tolerancia:

```text
Z_contact = 0.5*(C_left.z + C_right.z)
rollCenterHeight = RC_Z - Z_contact
```

Con niveles incompatibles, la coordenada RC puede seguir siendo finita pero
`rollCenterHeight_m` es `NaN` con `CONTACT_LEVEL_MISMATCH`.

## Heave simétrico y migración

v0.4 define únicamente:

```text
wheelTravel_left = wheelTravel_right = z
```

Cada lado usa el solver v0.2 y su continuation. No existe DOF de carrocería:
el chasis permanece fijo. Para cada target con convergencia bilateral se
calculan `RC_Y(z)`, `RC_Z(z)` y, cuando existe referencia común,
`RCHeight(z)`. Esto no es migración durante body roll.

## Benchmarks analíticos v0.4

En el benchmark simétrico los ejes interiores son longitudinales. En el lado
izquierdo las líneas UCA/LCA se intersectan exactamente en:

```text
IC_left = [-1/10, 1/4] m
contact_left = [-13/20, 0] m
```

El lado derecho es su reflexión. Las líneas contacto–IC se cruzan en:

```text
RC = [0, 13/44] m
```

Estos valores se derivan de ecuaciones lineales, no de la implementación.

El benchmark asimétrico conserva el lado izquierdo y define:

```text
IC_right = [-1/5, 3/10] m
contact_right = [13/20, 0] m
```

Resolviendo independientemente las dos rectas:

```text
RC_Y = -247/3020 m
RC_Z = 429/1661 m
```

El Y no nulo protege frente a implementaciones que fuercen centerline.

El benchmark proyectivo hace paralelas las restricciones upper/lower de cada
lado. En el lado izquierdo su dirección tiene pendiente `dZ/dY=-1/3` y pasa
por el contacto `[-13/20,0]`; la reflexión derecha tiene pendiente `+1/3` y
pasa por `[13/20,0]`:

```text
left construction:  Z = -(Y+13/20)/3
right construction: Z =  (Y-13/20)/3
RC = [0,-13/60] m
```

Ambos FVIC están en infinito, pero las dos líneas contacto–dirección se
intersectan en ese roll center finito.

## Tolerancias

`AbsTol = 1e-9 m` y `RelTol = 1e-9` son tolerancias de software. No representan fabricación, montaje, diseño ni optimización.

## Benchmark analítico

El benchmark usa ejes interiores UCA/LCA paralelos a X, brazos superiores e inferiores iguales y un tie rod compatible. UBJ, LBJ y tie-rod outboard comparten el mismo movimiento circular de radio `r=0.3 m`, de modo que el upright se traslada sin rotar.

Para un wheel travel `w` en la rama próxima al estado estático:

```text
deltaX = 0
deltaY = r - sqrt(r^2 - w^2)
R = I
camber = 0
```

Este resultado se deriva de la ecuación del círculo y no del solver.

## Límites geométricos

`CONTACT_PATCH` continúa rígidamente unido al upright en el estado cinemático.
v0.4 añade un contacto circular ideal para la construcción de roll center;
v0.5 reutiliza ese contacto para scrub y mechanical trail. No se publica
pneumatic trail.

La geometría proyectiva YZ de v0.4 conserva un IC en infinito como dirección.
Por ello puede construir su línea contacto–IC y, junto al otro lado, producir
un roll center finito o infinito. Esto sigue siendo una construcción
cinemática ideal: no añade compliance ni interpretación de fuerzas.

La regresión numérica 3D estima velocidades de ball joint alrededor de
`wheelTravel=20 mm` con diferencia central usando `h=1e-5 m`. Ese paso es una
elección de verificación del test, no una constante del solver ni una
tolerancia física.

## Actuation rod y rocker v0.7

Para el eje orientado `(O,u)`, con `||u||=1`, y el rocker rod point estático
`P0`:

```text
v = P0-O
vParallel = u*(u dot v)
C = O+vParallel
r = P0-C
t = u cross r
P(theta) = C+r*cos(theta)+t*sin(theta)
```

Se verifican `||r||=||t||` y `r dot t=0`. Con suspension point actual `S`,
`w=C-S` y longitud rígida `Lrod,0`, el closure es:

```text
A = 2*(w dot r)
B = 2*(w dot t)
D = Lrod,0^2-||w||^2-||r||^2
A*cos(theta)+B*sin(theta)=D
R=hypot(A,B)
alpha=atan2(B,A)
theta=alpha +/- acos(D/R)
```

Antes de evaluar `acos`, se clasifica tangencia cuando
`abs(abs(D)-R)<=toleranceCoefficient`. En ese caso se fuerza el cociente a
`sign(D)`, se publica una única raíz y conditioning exactamente cero. El
cociente no se recorta en el caso general. `|D|>R+toleranceCoefficient` es una
incompatibilidad física. `R≈0,D≈0` es underconstrained; `R≈0,D!=0` no tiene
solución.

El conditioning publicado es:

```text
abs(-A*sin(theta)+B*cos(theta))/R
```

y tiende a cero en tangencia. El umbral `sqrt(eps)` es exclusivamente numérico.

La rotación de UCA/LCA usa el eje interior orientado FWD→AFT. Proyectando el
ball joint estático/actual perpendicularmente al eje:

```text
beta=atan2(u dot (r0 cross r1), r0 dot r1)
```

Todo punto unido al brazo se rota rígidamente beta alrededor de esa línea.

```text
damperCompression = Ldamper,0-Ldamper
MR = d(damperCompression)/d(wheelTravel)
installationRatio = abs(MR)
Gtheta = d(theta)/d(wheelTravel)
```

Las derivadas de sweep se obtienen del interpolante cuadrático local de tres
muestras: central en interiores y unilateral de segundo orden en extremos,
incluido spacing no uniforme.
Solo se publican con al menos tres estados válidos y wheel travel estrictamente
monótono (creciente o decreciente), sin reordenar el sweep. La referencia
estática se identifica por `requestedWheelTravel_m==0`; el valor logrado puede
contener el pequeño residuo numérico admitido por el contrato cinemático.

## Spring, Damper & Wheel Rate v0.8

Para el coilover ideal, z es achieved wheel travel y c compresión del damper:

```text
Lseat,0 = Lfree-xPreload
seatOffset = Lseat,0-Ldamper,0
Lseat = Ldamper+seatOffset = Lseat,0-c
xRaw = xPreload+c; x=max(xRaw,0); gap=max(-xRaw,0)
Lspring=Lfree-x; Fs=k*x; U=0.5*k*x^2
MR=dc/dz
springWheelResistance = dU/dz = Fs*MR
wheelRateElastic = k*MR^2             (engaged branch)
wheelRateGeometric = Fs*dMR/dz
wheelRateTotal = wheelRateElastic+wheelRateGeometric
vd = MR*vWheel
Fd = cBranch*vd                      (linear asymmetric)
damperWheelResistance = MR*Fd
P = Fd*vd = damperWheelResistance*vWheel >= 0
```

La fuerza aplicada a z es el negativo de la resistencia generalizada. Con
xRaw<0, Fs=U=Kw=0 lejos de engagement; con xRaw=0 el tangent bilateral no es
único y se publica NaN. En coil bind no se prolonga la ley beyond solid height.
No se deduce equilibrio, carga de contacto ni estabilidad global.

La derivada segunda usa c original sobre tres samples vecinos. Con
`t=(zNeighbor-zCurrent)/h`, `h=max(abs(zNeighbor-zCurrent))`, se resuelve
`[1,t,t^2]*q=cNeighbor-cCurrent`; `dMR/dz=2*q(3)/h^2`.
Es exacta para c cuadrática; en malla uniforme interior el error es O(h^2),
y en extremos/malla arbitraria en general O(h). MR de producción permanece
el first derivative del análisis v0.7; el camino prescrito usa q(2)/h.
No se diferencia dos veces una curva MR aproximada. Safeguards, statuses,
tablas y benchmarks completos en [especificación mecánica](spring-damper-wheel-rate.md).

### F-01: sensibilidad numérica de las derivadas (sin nueva ley física)

En un stencil de tres abscisas x_i, con j,l los otros índices:

```text
w1_i(z) = (2*z-x_j-x_l)/((x_i-x_j)*(x_i-x_l))
w2_i = 2/((x_i-x_j)*(x_i-x_l))
e_i = eC_i+max(abs(MR),abs(diff(c)/diff(z)))*eZ_i
E_MR = sum(abs(w1_i)*e_i)+16*eps(abs(MR))
E_c2 = sum(abs(w2_i)*e_i)+16*eps(abs(c2))
E_F = k*eC_current+16*eps(abs(Fs))
E_geo = abs(Fs)*E_c2+abs(c2)*E_F+E_F*E_c2+16*eps(abs(Fs*c2))
E_elastic = k*(2*abs(MR)*E_MR+E_MR^2)     (0 si unseated)
E_Kw = E_elastic+E_geo+16*eps(abs(Kw_candidate))
```

Producción suma a E_MR la diferencia entre MR validado v0.7 y MR cuadrático
centrado; usa el primero para proyección. Pesos calculados en coordenadas
normalizadas. eC/eZ proceden de representación floating-point y, en producción,
indicadores dimensionales de residual/conditioning; definición exacta en la
[política F01-1](spring-damper-wheel-rate.md#f-01-representation-sensitivity-independently-of-matrix-conditioning).
No son incertidumbres físicas ni cotas rigurosas del error de solver.

Lref=Lfree y kref=k. Presupuestos: T_MR=1e-6+1e-3*abs(MR),
T_c2=1e-6/Lref+1e-3*abs(c2), T_Kw=1e-6*kref+1e-3*abs(Kw_candidate).
MR tiene criterio independiente; curvatura exige E_c2<=T_c2 y E_Kw<=T_Kw,
con valores finitos y safeguards previos. No se acepta curvatura deficiente
por tener poca fuerza. Se conservan fuerzas/damping con MR fiable, pero no
se fabrica un Kw total sin término geométrico. Truncación no está incluida en
estos estimadores; AVAILABLE no garantiza precisión total ni fabricación.

## Vehicle Parameters & Static Load Equilibrium v0.9

M=sum(m_i), rCG=sum(m_i*r_i)/M; coordenada desconocida no se inventa.
Suelo horizontal sin otras cargas: W=M*g, suma N=W,
suma x_i*N_i=W*xCG, suma y_i*N_i=W*yCG. Altura CG no aparece.
Para ejes X=0/L: NF=W*(L-xCG)/L; NR=W*xCG/L.
A=[1,1,1,1; xContacts'; yContacts'], b=W*[1;xCG;yCG].
Rango tres deja un grado: N=N0+lambda*n, A*n=0. Intersectar N_i>=0
da intervalo admisible; N0 nunca se publica como distribución única.
CW=(FR+RL)/W añade fila [0,1,1,0]. Simetría es hipótesis explícita,
medidas conservan su residual, y falta de cuarta condición queda indeterminada.
M_sprung=M-totalUnsprung sólo con datos completos; soporte local=N_i-m_ui*g
bajo hipótesis concentrada/vertical ideal, no fuerzas de todos los links 3D.

Equilibrio local: Fs(z)*MR(z)=support_target, con MR firmado y damping=0.
Interpolación lineal de fuerza validada: a=(target-Fi)/(Fj-Fi),
z_eq=zi+a*(zj-zi). Root exacta DEL interpolante, no del mecanismo continuo.
Kw completo validado v0.8 clasifica pendiente local, no estabilidad global;
con F-01 no fiable no se sustituye Kw por término elástico ni secante.
Método, error proxies, tolerancias numéricas y limits de completitud en
[contrato v0.9](vehicle-static-equilibrium.md).

Correcciones de auditoría v0.9: SL-32 separa residual de equilibrio, error de
roundoff y N_i>=0. La sensibilidad por sigmaMin del sistema escalado produce
presupuestos en N y se propaga a los cocientes -N0_i/n_i (lambda también en N).
Un intervalo puntual numérico conserva nullspace de dimensión 1. Candidatos
de frontera se verifican contra las filas originales, incluida CW, antes y
después de cualquier corrección estrictamente negativa de roundoff. Medidas
no se corrigen. Soporte negativo no se recorta. Fórmulas, origen y limitaciones
del presupuesto en la sección SL-32 del contrato; no cambia ninguna ley v0.8.

## Pending mathematical specifications (después de v0.10)

No están especificados ni implementados roll axis de vehículo, steering
wheel/column, pinion ratio, fuerzas estructurales o compliance, pneumatic trail,
ARB, anti geometry, neumáticos laterales/longitudinales, contacto dependiente de camber ni dinámica.
