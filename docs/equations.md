# Convenciones matemáticas

Este documento contiene únicamente operaciones definidas en v0.1; no anticipa el solver.

## Puntos y vectores

- Cálculo numérico en `double`.
- Punto devuelto por API: fila `[x, y, z]`.
- Colección de puntos: matriz `N×3`.
- Posiciones internas: metros.
- Todo valor geométrico debe ser real y finito.

Vector desde A hasta B:

`v_AB = p_B - p_A`

Distancia:

`d(A,B) = norm(p_B - p_A, 2)`

Vector unitario, únicamente si A y B no coinciden:

`u_AB = v_AB / norm(v_AB, 2)`

## Sistema de coordenadas

X apunta hacia atrás, Y hacia la derecha y Z hacia arriba. Es un sistema diestro:

`e_X × e_Y = e_Z`

El origen y los signos se definen completamente en `coordinate-system.md`.

## Reflexión lateral

```text
M_Y = diag([1, -1, 1])
p_mirror = M_Y * p
wheelAxis_mirror = M_Y * wheelAxis
```

`det(M_Y) = -1`; no es una rotación. La reflexión conserva distancias y, aplicada dos veces, recupera el dato original dentro de las tolerancias numéricas.

## Tolerancias

`AbsTol = 1e-9 m` y `RelTol = 1e-9`. Son tolerancias de software, no tolerancias físicas. La coincidencia elemental usa:

`norm(pB-pA) <= AbsTol + RelTol*max(norm(pA), norm(pB), 1 m)`

## Unidades

- `m = mm / 1000`;
- los ángulos futuros se almacenarán en radianes.

La conversión de longitud ocurre en el constructor y no en las operaciones geométricas.

## Pending mathematical specifications

No están especificados ni implementados:

- upright pose y wheel travel constraints;
- camber, toe, caster y KPI;
- scrub radius y trail;
- instant centers y roll center;
- steering y Ackermann;
- anti geometry;
- actuation y motion ratio.

Cada futura especificación deberá documentar frames, signos, unidades, singularidades, tolerancias, hipótesis y un caso conocido antes de codificarse.

