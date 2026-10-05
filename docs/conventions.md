# Convenciones

## Unidades internas

Se recomienda SI coherente:

| Magnitud | Unidad interna | Presentación típica futura |
|---|---:|---:|
| Longitud | metro (`m`) | milímetro (`mm`) |
| Ángulo | radián (`rad`) | grado (`deg`) |
| Fuerza | newton (`N`) | N o kN |
| Masa | kilogramo (`kg`) | kg |
| Tiempo | segundo (`s`) | s |

Los metros mantienen coherencia directa con N, kg y s para módulos dinámicos futuros y evitan factores ocultos al integrar con el ecosistema SI. Las dimensiones de una suspensión, típicamente décimas de metro, siguen teniendo una escala numérica razonable en doble precisión. MATLAB usa radianes en sus funciones trigonométricas básicas; los grados son una preocupación de presentación.

Las conversiones solo se realizan en fronteras de entrada/salida. El núcleo no acepta valores “a veces mm, a veces m”. Los nombres de campos serializados que contienen magnitudes deben incluir unidad cuando ayude a impedir ambigüedad, por ejemplo `xyz_m`; las variables algebraicas pueden omitirla cuando el contrato ya fija la unidad.

> **OPEN DECISION UN-001 — Unit-aware input API:** decidir en v0.1 si la API pública acepta exclusivamente SI o también un valor acompañado de unidad. En ambos casos, el almacenamiento canónico seguirá siendo SI.

## Identificadores de hardpoints

Se compararon tres estilos:

1. **Muy compacto** (`FL_UCAF`): cómodo en croquis, pero ambiguo, difícil de buscar y poco extensible.
2. **Completamente descriptivo** (`FrontLeftUpperControlArmForwardChassisPivot`): legible una vez, pero largo, propenso a variantes y poco práctico en tablas.
3. **ID corto estable + display name**: identificador técnico inequívoco y una etiqueta humana/localizable independiente.

Se recomienda la tercera opción. El ID canónico completo usa ASCII y `UPPER_SNAKE_CASE`:

`<CORNER>_<POINT_ROLE>`

Ejemplo: `FL_UCA_FWD_CHASSIS`. Dentro de un objeto que ya declara `cornerId = "FL"`, se almacena el rol `UCA_FWD_CHASSIS`; el ID completo se forma solo para logs, exportación o claves globales. No se usa la nomenclatura de Adams como modelo interno.

Reglas léxicas:

- Esquinas: `FL`, `FR`, `RL`, `RR`.
- Componentes comunes: `UCA`, `LCA`, `UBJ`, `LBJ`.
- Direcciones longitudinales: `FWD` y `AFT`; se evita `REAR` para un pivot porque puede confundirse con el eje trasero.
- Ubicación transversal: `INBOARD` y `OUTBOARD` cuando expresa pertenencia funcional, no simplemente el signo Y.
- Los IDs nunca contienen unidad, nombre del proveedor ni texto localizado.
- `displayName` es presentación y puede cambiar sin migrar datos; el ID no cambia sin una migración de schema.

### Roles v0.1 recomendados

| Point role ID | Display name inglés | Descripción |
|---|---|---|
| `UCA_FWD_CHASSIS` | UCA forward chassis pivot | Pivot delantero del brazo superior en chasis. |
| `UCA_AFT_CHASSIS` | UCA aft chassis pivot | Pivot posterior del brazo superior en chasis. |
| `UBJ` | Upper ball joint | Unión superior upright–brazo. |
| `LCA_FWD_CHASSIS` | LCA forward chassis pivot | Pivot delantero del brazo inferior en chasis. |
| `LCA_AFT_CHASSIS` | LCA aft chassis pivot | Pivot posterior del brazo inferior en chasis. |
| `LBJ` | Lower ball joint | Unión inferior upright–brazo. |
| `WHEEL_CENTER` | Wheel center | Centro de rueda/hub en la condición de referencia. |
| `CONTACT_PATCH` | Contact patch reference | Punto de referencia del contacto en la condición estática. |

`WHEEL_CENTER` y `CONTACT_PATCH` son puntos geométricos de referencia aunque no sean joints mecánicos. El nombre genérico “hardpoint” se utilizará para el conjunto de puntos canónicos, dejando `kind` o `role` para distinguir pivots, joints y referencias.

### Roles futuros reservados, no implementados

| Point role ID recomendado | Uso futuro |
|---|---|
| `TIE_ROD_INBOARD` / `TIE_ROD_OUTBOARD` | Extremos del tie rod. |
| `ACTUATION_OUTBOARD` / `ACTUATION_ROCKER` | Extremos funcionales del pushrod o pullrod. |
| `ROCKER_PIVOT` | Eje/punto de pivot del rocker según su modelo futuro. |
| `DAMPER_FIXED` / `DAMPER_MOVING` | Anclajes fijo y móvil del amortiguador. |
| `RACK_LEFT_JOINT` / `RACK_RIGHT_JOINT` | Joints internos izquierdo y derecho sobre la cremallera. |
| `RACK_HOUSING_LEFT_MOUNT` / `RACK_HOUSING_RIGHT_MOUNT` | Montajes de carcasa si packaging los necesita. |

Estos nombres reservan vocabulario, no contratos ni geometría.

> **OPEN DECISION NM-001 — Actuation IDs:** confirmar si los endpoints deben ser genéricos (`ACTUATION_*`, recomendado) con `mechanismType`, o específicos (`PUSHROD_*`/`PULLROD_*`). Se decidirá al diseñar actuación.

> **OPEN DECISION NM-002 — Rocker representation:** decidir si `ROCKER_PIVOT` será un punto más un eje, o dos puntos que definan el eje. Un único punto no define una rotación 3D.

> **OPEN DECISION NM-003 — Wheel orientation:** decidir qué dato canónico define el eje de rueda y su orientación estática. `WHEEL_CENTER` y `CONTACT_PATCH` por sí solos no fijan completamente la pose 3D.

## Datos conocidos y asumidos

Todo input futuro llevará procedencia explícita. El vocabulario inicial recomendado es `KNOWN`, `ASSUMED` y `DERIVED`; v0.1 necesita al menos los dos primeros. Un valor asumido debe incluir una nota o referencia. “Default” describe cómo se obtuvo un valor, no su validez física, y no sustituye a la procedencia.

