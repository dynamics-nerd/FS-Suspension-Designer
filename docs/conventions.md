# Convenciones

## Unidades

El núcleo utiliza SI: m, rad, N, kg y s. Las APIs de geometría y wheel travel aceptan `"m"` o `"mm"`; convierten en la frontera mediante `fsd.model.convertLengthToMetres`.

## Hardpoint IDs v0.2

Cada ID es `<CORNER>_<POINT_ROLE>`, con corner `FL`, `FR`, `RL` o `RR`. Son obligatorios:

- `UCA_FWD_CHASSIS`, `UCA_AFT_CHASSIS`, `UBJ`;
- `LCA_FWD_CHASSIS`, `LCA_AFT_CHASSIS`, `LBJ`;
- `TIE_ROD_INBOARD`, `TIE_ROD_OUTBOARD`;
- `WHEEL_CENTER`, `CONTACT_PATCH`.

`TIE_ROD` es el nombre técnico genérico también para una futura toe link trasera. `TIE_ROD_INBOARD` permanece fijo en la cinemática de esquina aislada y `TIE_ROD_OUTBOARD` forma parte del upright rígido. En `SteeringSystemGeometry` delantero, los dos inboards son los joints de un rack rígido y se trasladan juntos.

IDs estables y `displayName` continúan separados.

## Procedencia

`sourceKind` y `sourceNote` son `N×3`, una entrada para X/Y/Z. Los kinds admitidos son `KNOWN`, `ASSUMED`, `DERIVED` y `UNSPECIFIED`. No representan el estado futuro `FIXED/RANGE/FREE`.

## Upright rígido

Son solidarios UBJ, LBJ, `TIE_ROD_OUTBOARD`, Wheel Center, Contact Patch y wheel axis. UBJ/LBJ/tie-rod-outboard deben ser distintos y no collineales. No existe compliance.

## Wheel travel

`wheelTravel = Z_WC,current - Z_WC,static`:

- positivo: bump/jounce;
- negativo: rebound/droop;
- cero: estado estático.

## Wheel axis, camber y toe

El wheel axis unitario apunta interior→exterior. La pose actual lo obtiene rotando el eje estático con la misma matriz del upright.

Camber negativo significa parte superior hacia el centro; positivo, hacia fuera. El valor del núcleo está en radianes. La ecuación simétrica por lado está en `equations.md`.

Toe positivo significa toe-in y toe negativo significa toe-out. Se obtiene solo de la proyección XY del wheel axis; la componente Z debida a camber no puede crear toe ficticio. Los ejes nominales `[0,-1,0]` para FL/RL y `[0,+1,0]` para FR/RR producen toe cero.

## Steering axis, caster y kingpin inclination

El steering axis unitario apunta siempre desde LBJ hacia UBJ. Su componente Z no se fuerza a ser positiva: una geometría inusual sigue conservando el sentido físico LBJ→UBJ y se interpreta con `atan2`.

- caster positivo: UBJ desplazado hacia `+X` (parte trasera) respecto a LBJ;
- `kingpinInclination`/KPI positivo: extremo superior del eje hacia el centro del vehículo;
- en FR/RR, KPI positivo implica menor Y en UBJ; en FL/RL, mayor Y;
- caster y KPI se almacenan en radianes.

## Bump steer

```text
bumpSteer(z) = toe(z) - toe(0)
```

Se conservan por separado `staticToe_rad`, `toe_rad` y `bumpSteer_rad`. `toe(0)` procede de la geometría estática, aunque el sweep solicitado no incluya cero.

El primer punto y el punto más próximo a cero nunca sustituyen a `toe(0)`. Esto aplica igualmente a sweeps solo positivos, solo negativos o que salten directamente de rebound a bump.

## Convergencia y status

- `converged=true` exige exclusivamente `status="CONVERGED"` y payload físico finito y coherente.
- `converged=false` admite exclusivamente `NO_CONVERGENCE` o `NOT_ATTEMPTED`.
- Un resultado no convergido conserva target, causa, diagnósticos y referencia estática, pero estado móvil, pose calculada, wheel axis, travel logrado y métricas permanecen en `NaN`.
- Strings desconocidos o contradicciones entre flag y status invalidan el resultado completo.

`diagnostics.attempted` es booleano y no se deduce de iteraciones:

- `CONVERGED`: `attempted=true`, incluso para un estado exacto reutilizado;
- `NO_CONVERGENCE`: `attempted=true`, aunque el fallo ocurra antes de completar una iteración formal;
- `NOT_ATTEMPTED`: `attempted=false` y cero iteraciones, evaluaciones, pasos de continuation y exit flag.

Los corner IDs admiten un char row como `'FL'` o un string escalar no missing. Matrices char, arrays string y valores multidimensionales se rechazan.

## Solver

v0.2 usa `fsolve` de Optimization Toolbox. Configuración central:

- continuation step máximo: `0.005 m`;
- Function/Step/Optimality tolerance: `1e-12`;
- máximo 200 iteraciones y 2000 evaluaciones por paso.

Son parámetros numéricos, no límites físicos. Pueden sobrescribirse mediante un options struct validado. La aceptación final sigue las tolerancias dimensionales de `fsd.model.numericTolerances`.

## Visualización

El núcleo mantiene m/rad. Las funciones de plot convierten wheel travel a mm y ángulos a grados exclusivamente en la frontera de presentación.

## Eje y vista frontal v0.4

- `FRONT` exige `FL` a la izquierda y `FR` a la derecha; `REAR`, `RL/RR`.
- No se exige simetría. El lado procede del corner ID, no del signo Y.
- La vista frontal es el plano matemático YZ: Y negativa a la izquierda,
  positiva a la derecha y Z positiva hacia arriba.
- No existe `xReference_m`: la restricción YZ se obtiene de la cinemática 3D
  real de cada eje interior y de su ball joint. Wheel stagger sigue siendo
  válido y no crea una dependencia entre corners.
- Los statuses de intersección son `FINITE`, `INFINITE`, `COINCIDENT` y
  `DEGENERATE`. `INFINITE` conserva una dirección proyectiva unitaria, pero
  sus coordenadas euclídeas son `NaN`; nunca se usa una distancia enorme.
- `conditioning` es el valor absoluto del seno del ángulo entre las normales
  unitarias de dos líneas. `isIllConditioned` advierte de intersecciones
  finitas sensibles sin alterar su clasificación geométrica.

## Contacto y altura de roll center

`CONTACT_PATCH` sigue siendo un punto material del upright. El análisis v0.4
exige además que, en estático, coincida con el punto inferior de la rueda
circular ideal y con `Z=0`. Esta precondición se comprueba al entrar en el
análisis; no invalida retroactivamente una geometría v0.3.

`rollCenterZ_m` es coordenada en el frame global/chassis. Solo se publica
`rollCenterHeight_m` cuando los contactos geométricos izquierdo y derecho
comparten Z dentro de tolerancia; entonces se resta su nivel común.

Symmetric axle heave significa exclusivamente `zLeft=zRight` de wheel travel
respecto al chasis fijo. No representa body heave ni body roll.

El roll center de v0.4 es una construcción cinemática frontal. No implica una
línea de acción de fuerza, compliance ni un centro de fuerza.

## Dirección por rack v0.5

Los puntos estáticos `P_L=FL_TIE_ROD_INBOARD` y
`P_R=FR_TIE_ROD_INBOARD` definen el eje unitario canónico
`u_rack=(P_R-P_L)/norm(P_R-P_L)`. Su sentido positivo es siempre izquierda
hacia derecha, aunque tenga componentes X o Z. Un rack travel `q` positivo
desplaza ambos puntos mediante `P_current=P_static+q*u_rack`; no presupone un
sentido de giro. La separación de joints es constante y el rack no rota.

El road-wheel heading es una dirección horizontal unitaria orientada hacia el
frente. Recto equivale a `[-1,0,0]`. El ángulo absoluto se mide respecto a
`-X`: positivo apunta hacia `+Y` (giro a la derecha), negativo hacia `-Y`
(giro a la izquierda), igual para FL y FR. Todos los ángulos internos están
en radianes y las diferencias se envuelven con `atan2(sin(delta),cos(delta))`.

Se conservan por separado:

- `toe`: orientación del wheel axis con positivo toe-in;
- `steerDeflectionFromStatic`: heading actual menos heading estático;
- `rackInducedSteer`: heading actual menos el heading a igual wheel travel y
  rack cero.

El scrub radius usa el contacto geométrico actual `C` y la intersección `S`
del eje LBJ→UBJ con el plano horizontal `Z=C_z`:
`scrub=sideSign*(C_y-S_y)`. Positivo significa contacto más outboard que la
intersección en ambos lados. Mechanical trail es `C_x-S_x`; con X hacia atrás,
es positivo cuando el eje corta el suelo por delante del contacto. No es
pneumatic trail.

Ackermann usa la línea trasera `X=rearAxleX` y los contactos/headings reales.
El sentido y las ruedas inner/outer se deducen del steering inducido por rack,
nunca del signo de `q`. Cerca de recto, un ICR se representa como infinito y
el análisis devuelve status explícito; no publica un porcentaje Ackermann.

Un `SteeringAxleResult` no convergido invalida las métricas derivadas de ambos
lados, aunque una esquina haya convergido individualmente. Los payloads de
análisis usan `KINEMATICS_NOT_CONVERGED` y `NaN`; conservan por separado el
flag, status, failure reason y diagnostics cinemáticos de FL y FR.

## Body roll y carretera v0.6

`bodyRollAngle=phi` es una rotación de mano derecha alrededor de `+X`. Como X
apunta hacia atrás, `phi>0` hace subir el lado derecho del chasis y bajar el
izquierdo respecto al mundo. Equivalentemente, una carretera horizontal en el
mundo aparece en coordenadas del chasis descendiendo hacia `+Y`.

En YZ del chasis:

```text
dRoad = [cos(phi), -sin(phi)]       % izquierda -> derecha
nRoad = [sin(phi),  cos(phi)]       % normal orientada hacia +Z
```

Se exige `abs(phi)<pi/2` para conservar sin ambigüedad la orientación
izquierda→derecha (`dRoad_Y>0`) y una normal con componente Z positiva. No es
un límite físico de Formula Student.

Recorrido asimétrico significa un input directo `[zLeft,zRight]`. Body roll es
un problema distinto: recibe `phi` y
`axleHeave=(zLeft+zRight)/2`, y resuelve el diferencial requerido por los
contactos reales. Este axle heave es el recorrido vertical medio de los Wheel
Centers respecto al chasis, no una coordenada de vehículo completo.

Camber histórico pasa a denominarse explícitamente **chassis-relative
camber**. **Road-relative camber** rota el wheel axis mediante `Rx(+phi)` a un
frame road-aligned y aplica después exactamente la misma convención histórica.

`rollCenterZ_m` sigue siendo la coordenada Z del chasis. La métrica histórica
`rollCenterHeight_m` solo existe para contactos al mismo Z. La nueva
`rollCenterRoadHeight_m` es distancia perpendicular firmada respecto a la
road line normalizada y queda `NaN` si el RC no es finito.

Se distinguen:

- `wheelCenterTrack = Y_WC,right - Y_WC,left` en el frame del chasis;
- `geometricContactTrack = dRoad dot (C_right-C_left)` sobre la carretera;
- sus cambios respecto al estado estático de la misma geometría `h=0,phi=0`.

El Ackermann v0.5 sigue definido en plan view del frame del chasis. No se
publica como Ackermann exacto durante roll; una formulación futura deberá
trabajar en un frame alineado con carretera.

Los fallos de cierre distinguen `ROOT_NOT_BRACKETED` cuando existen muestras
válidas pero no encierran raíz, `KINEMATIC_NONCONVERGENCE` cuando no existe
dominio válido suficiente para evaluarla, y `SCALAR_NO_CONVERGENCE` cuando un
bracket válido no supera el root solve o su post-check. En análisis de sweep,
estos statuses se conservan como `kinematicStatus`; el status genérico de que
no hay métricas se publica separadamente como `analysisStatus`.

## Actuación v0.7

- IDs: `ACTUATION_ROD_SUSPENSION`, `ACTUATION_ROD_ROCKER`, `DAMPER_ROCKER` y
  `DAMPER_CHASSIS`.
- `actuationType` es `PUSHROD` o `PULLROD`. Es una elección arquitectónica e
  identitaria; no cambia el cierre cinemático de un rod rígido.
- `attachmentBody` es `UPRIGHT`, `UCA` o `LCA`.
- El rocker axis es la línea orientada `P+lambda*u`. `P` se canonicaliza como
  el punto de la línea más próximo al origen y `u` es unitario.
- Ese punto canónico no representa bearings ni brackets. Sus futuras
  ubicaciones físicas pertenecerán a packaging y no a la identity cinemática
  de la línea.
- `u` y `-u` representan la misma línea física pero distintas convenciones de
  signo. El vector orientado forma parte de la identity y define
  `rockerAngle>0` por mano derecha.
- `YZ_PLANE` fija `u=[1,0,0]`; `XZ_PLANE` fija `u=[0,1,0]`; `CUSTOM` conserva
  un vector 3D arbitrario orientado. Un rocker en XY se expresa como CUSTOM
  con eje paralelo a Z.
- `orientationMode` es una ayuda de entrada y permanece en el modelo para
  trazabilidad, pero no forma parte de la identity física. Dos definiciones
  con el mismo eje canónico tienen la misma identity aunque usen preset o
  CUSTOM.
- La geometría estática introducida es `rockerAngle=0`.
- `damperCompression=Ldamper,0-Ldamper`: positivo significa que se acorta.
- En sweeps, `maximumCompression` y `maximumExtension` son magnitudes no
  negativas respecto al estado estático; valen cero si el path no alcanza el
  sentido correspondiente. `totalRequiredStroke=max(L)-min(L)`.
- `damperMotionRatio=d(damperCompression)/d(wheelTravel)`; positivo corresponde
  normalmente a bump que comprime el damper.
- `installationRatio=abs(damperMotionRatio)` y nunca significa el cociente
  inverso.
- `rockerAngularGain=d(rockerAngle)/d(wheelTravel)` en rad/m.
- Las curvas derivadas requieren al menos tres muestras y wheel travel
  estrictamente creciente o decreciente. La referencia estática de migración
  es el índice cuyo target solicitado vale exactamente cero.

PUSHROD/PULLROD no predice si el miembro trabaja a tracción o compresión. Esa
validación requiere fuerzas y queda fuera de v0.7.

## Decisiones aún abiertas

No hay OPEN DECISIONS activas al cerrar v0.7.
