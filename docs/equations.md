# Convenciones matemáticas

Este documento fija solo operaciones completamente definidas. No contiene ni anticipa el solver de suspensión.

## Escalares, puntos y vectores

- Los escalares y arrays de cálculo usan `double` salvo justificación documentada.
- Un punto individual se interpreta algebraicamente como vector columna `p = [x; y; z]`.
- Una colección se almacena en MATLAB como `N×3`, con un punto por fila: `[x, y, z]`.
- Todas las coordenadas internas de posición están en metros.
- Los valores deben ser reales y finitos antes de entrar en operaciones geométricas.

El vector desde `p_A` hasta `p_B` es:

`v_AB = p_B - p_A`

La distancia euclídea es:

`d(A,B) = norm(p_B - p_A, 2)`

No se fija todavía una tolerancia universal para decidir coincidencia; véase `OPEN DECISION CS-002`.

## Sistema de coordenadas

Se usa el marco diestro del vehículo definido en `coordinate-system.md`: X hacia delante, Y hacia la izquierda y Z hacia arriba. Se cumple:

`e_X × e_Y = e_Z`

Los ángulos internos se expresan en radianes. Todo ángulo firmado futuro deberá documentar eje, sentido positivo, vista y orden de rotaciones antes de implementarse.

## Transformaciones rígidas básicas

Para una rotación propia `R` y una traslación `t`, ambas expresadas en un contrato de frames explícito:

`p_B = R_BA * p_A + t_BA`

con:

- `R_BA' * R_BA = I`;
- `det(R_BA) = +1`;
- `t_BA` en metros.

En coordenadas homogéneas:

```text
T_BA = [R_BA  t_BA]
       [0 0 0    1 ]
```

y `[p_B; 1] = T_BA * [p_A; 1]`. El orden y los subíndices deben figurar en el nombre o contrato; no se admite una función genérica que oculte qué frame entra y sale.

## Reflexión lateral

Para puntos expresados respecto del plano central `Y = 0`:

```text
M_Y = diag([1, -1, 1])
p_mirror = M_Y * p
```

`det(M_Y) = -1`; por tanto `M_Y` no es una rotación ni una pose rígida propia. La reflexión conserva distancias entre puntos polares, pero no puede reutilizarse sin especificación para vectores axiales, frames u orientaciones.

## Unidades y conversiones

Longitud `m`, ángulo `rad`, fuerza `N`, masa `kg` y tiempo `s`. Ejemplos de frontera completamente definidos:

- `m = mm / 1000`;
- `rad = deg * pi / 180`.

Las conversiones no forman parte de los solvers y no se repiten en su interior.

## Pending mathematical specifications

Las siguientes materias no están definidas y ningún agente debe inventar ecuaciones para ellas:

- upright pose;
- wheel travel constraints;
- camber;
- toe;
- caster;
- kingpin inclination (KPI);
- instant centers;
- roll center;
- steering;
- anti geometry;
- actuation.

Cada especificación futura deberá incluir frames, signos, unidades, singularidades, tolerancias, hipótesis y al menos un caso conocido antes de codificarse.

