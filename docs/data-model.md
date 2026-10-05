# Modelo de datos

## Criterios

El modelo inicial debe ser explícito, serializable, fácil de validar y cómodo desde App Designer, sin penalizar futuras evaluaciones masivas. No se crearán clases por cada sustantivo del dominio.

Decisión inicial:

- `struct` escalar para agregar una geometría y sus metadatos;
- matrices `double` para coordenadas y cálculo vectorizado;
- vectores `string` para IDs estables y procedencia;
- funciones puras de construcción/validación cuando se implemente v0.1;
- tablas solo en fronteras de importación, presentación o informes;
- clases y enumeraciones solo cuando aporten invariantes o comportamiento que un contrato de struct no pueda mantener con claridad.

Los value objects de MATLAB pueden ser apropiados más adelante, pero en v0.1 añadirían coste de construcción y serialización sin una ventaja demostrada. Los handle objects se evitan en el núcleo porque el estado compartido y mutable dificulta la reproducibilidad de tests y optimizaciones.

## Entidades de v0.1

### Hardpoint

Es un concepto, no una clase individual. Se representa en un bloque columnar:

```matlab
hardpoints.ids          % N-by-1 string, roles canónicos únicos
hardpoints.xyz_m        % N-by-3 double, coordenadas de vehículo
hardpoints.sourceKind   % N-by-1 string: KNOWN o ASSUMED
hardpoints.sourceNote   % N-by-1 string, referencia o explicación
```

Esta forma evita arrays de objetos pequeños y permite vectorizar. La relación entre filas es contractual. La función de construcción futura deberá validar tamaños, unicidad, valores reales/finitos y vocabulario; no se deben construir estos structs ad hoc en la UI.

El estado de procedencia es inicialmente por punto. Si aparece un caso real con coordenadas de procedencia mixta, se ampliará mediante una nueva versión de schema en lugar de reinterpretar silenciosamente el campo.

### DoubleWishboneGeometry

Será el agregado raíz de una esquina estática:

```matlab
geometry.schemaVersion       % string
geometry.cornerId            % FL, FR, RL o RR
geometry.referenceFrame      % identificador + descripción de origen
geometry.hardpoints          % bloque definido arriba
geometry.connectivity        % pares de IDs para visualizar miembros
geometry.upright             % pertenencia/conectividad estática mínima
geometry.wheel               % referencias a WHEEL_CENTER y CONTACT_PATCH
geometry.metadata            % nombre, notas y procedencia del dataset
```

El ejemplo es un contrato conceptual, no código implementado. `connectivity` contiene topología para validación y dibujo, no restricciones cinemáticas.

### SuspensionCorner

No se crea como tipo separado en v0.1. `DoubleWishboneGeometry` ya representa una esquina y declara `cornerId`. Se reconsiderará cuando una esquina necesite combinar geometría, steering, actuación, estado y resultados sin mezclar responsabilidades.

### Upright

En v0.1 no será una clase. Será un pequeño struct dentro de la geometría que referencia IDs de puntos pertenecientes al upright y, como máximo, conectividad de dibujo. No calculará pose. La definición suficiente de orientación queda abierta en `conventions.md`.

### Wheel

En v0.1 no será una clase ni un modelo de neumático. Referenciará `WHEEL_CENTER` y `CONTACT_PATCH`. Un disco de rueda orientado o una envolvente 3D requiere una decisión adicional sobre el eje de rueda y queda fuera hasta resolver `OPEN DECISION NM-003`.

### SuspensionState

No tiene sentido en una geometría puramente estática y no se implementará en v0.1. Aparecerá con el solver para representar entradas o coordenadas generalizadas, siempre separado de la geometría de referencia.

### KinematicResult

No se implementará en v0.1. Cuando exista, será un resultado inmutable por evaluación que contenga estado resuelto, posiciones y métricas con sus convenciones, sin handles gráficos ni referencias a la UI.

## Serialización y evolución

- Usar un `schemaVersion` explícito desde el primer archivo persistido.
- Preferir MAT para fidelidad MATLAB y JSON para intercambio cuando el schema esté estabilizado.
- No serializar objetos gráficos, function handles ni instancias que dependan del path.
- No usar nombres de campos dinámicos para hardpoints; una tabla lógica `ids + xyz_m` permite validar y añadir roles sin alterar la forma del struct.
- Toda migración futura debe ser explícita y probada.

## Rendimiento futuro

La legibilidad domina en v0.1. Para optimización, el límite natural es convertir una geometría validada a matrices densas ordenadas una vez y evaluar lotes sin strings en el hot loop. No se diseña ahora un contenedor especializado ni se compromete el API público a una disposición de memoria prematura.

## Frontera con App Designer

La UI podrá trabajar con tablas para editar puntos, pero deberá enviarlas a una función del núcleo que convierta unidades, normalice IDs y produzca el struct canónico. Los callbacks no validarán geometría mediante lógica duplicada. Los mensajes de validación deben conservar identificadores de error estables para que la UI los traduzca.

## OPEN DECISIONS

- **DM-001 — Public constructor shape:** definir las firmas exactas de constructores/validadores al implementar v0.1.
- **DM-002 — Persistence format:** aprobar MAT, JSON o ambos una vez exista el primer dataset real.
- **DM-003 — Provenance granularity:** confirmar si la procedencia por hardpoint es suficiente o debe ser por coordenada desde v0.1.

## Referencias de implementación MATLAB

- [MathWorks — Structure arrays](https://www.mathworks.com/help/matlab/ref/struct.html).
- [MathWorks — User-defined classes](https://www.mathworks.com/help/matlab/matlab_oop/user-defined-classes.html).
- [MathWorks — Which kind of class to use](https://www.mathworks.com/help/matlab/matlab_oop/which-kind-of-class-to-use.html).
