# Convenciones y formulación matemática

## Sistema y unidades

El marco global es diestro: X hacia atrás, Y hacia la derecha y Z hacia arriba. Posiciones y wheel travel se almacenan en metros; rotaciones y camber, en radianes.

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

## Pending mathematical specifications

No están especificados ni implementados toe/bump steer, steering input, caster, KPI, scrub, trail, instant centers, roll center, anti geometry, actuation, compliance ni dinámica.
