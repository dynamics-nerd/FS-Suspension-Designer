# Convenciones y formulación matemática

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

Los pivotes interiores UCA/LCA y `TIE_ROD_INBOARD` permanecen fijos. El upright rígido contiene UBJ, LBJ, `TIE_ROD_OUTBOARD`, Wheel Center, Contact Patch y wheel axis.

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

## Límites geométricos v0.3

`CONTACT_PATCH` continúa rígidamente unido al upright en v0.2/v0.3 y no es el punto de intersección instantáneo de la rueda orientada con el plano de carretera. Por ello no se publican scrub radius ni mechanical/pneumatic trail: hacerlo daría una precisión física falsa.

Roll center e instant centers requieren como mínimo un modelo coherente de eje completo y una especificación de construcción geométrica. El modelo actual resuelve una sola esquina, por lo que se difieren explícitamente.

## Pending mathematical specifications

No están especificados ni implementados steering input/rack motion, Ackermann, scrub radius, trail, instant centers, roll center, anti geometry, actuation, compliance, neumáticos ni dinámica.
