# Roadmap

## Estado actual — Foundation

La estructura, las reglas de dependencia, las convenciones propuestas y la infraestructura mínima de tests están preparadas. No se ha implementado geometría de dominio ni cálculo de suspensión.

## v0.1 — Static Double Wishbone Geometry

### Incluido

- representación de una esquina de suspensión double wishbone;
- hardpoints estáticos en el marco del vehículo;
- wheel center y contact patch;
- upright básico como conectividad estática, sin resolver pose;
- validación de inputs, IDs, dimensiones, finitud, unicidad y presencia;
- representación 3D básica de puntos y miembros;
- tests de estructura y geometría elemental;
- un ejemplo pequeño y reproducible con datos declarados de demostración.

Hardpoints mínimos: `UCA_FWD_CHASSIS`, `UCA_AFT_CHASSIS`, `UBJ`, `LCA_FWD_CHASSIS`, `LCA_AFT_CHASSIS`, `LBJ`, `WHEEL_CENTER` y `CONTACT_PATCH`.

### No incluido

- bump/rebound solver o solver no lineal;
- camber gain o cálculo de camber;
- toe curve o cálculo de toe;
- steering;
- roll o pitch;
- caster o KPI;
- instant centers o roll center;
- pushrod, pullrod, rocker o motion ratio;
- neumático dinámico o dinámica vehicular;
- optimización;
- Rules Engine funcional o reglas Formula Student;
- Tilt Test;
- App Designer final;
- integración automática con Adams Car.

### Criterios objetivos de aceptación

v0.1 estará terminada cuando se cumplan todos:

1. Existe una API pública documentada que construye una geometría de una esquina sin depender de la UI ni del base workspace.
2. Un input válido produce el schema documentado, exclusivamente en SI y en el frame declarado.
3. Faltas, duplicados y IDs desconocidos; corner IDs inválidos; coordenadas no `1×3`, no numéricas, complejas o no finitas producen errores con identificadores estables.
4. Los ocho roles mínimos aparecen exactamente una vez.
5. Se validan al menos estos casos elementales bajo una política de tolerancia aprobada: pivots forward/aft de cada brazo no coincidentes, `UBJ ≠ LBJ` y `WHEEL_CENTER ≠ CONTACT_PATCH`.
6. La conectividad estática identifica dos segmentos por wishbone y los enlaces básicos del upright sin imponer constraints de movimiento.
7. Una función de representación 3D dibuja la geometría en ejes MATLAB suministrados o creados explícitamente, usa escala igual, etiqueta ejes/unidades y devuelve handles comprobables.
8. Tests automatizados cubren creación, forma XYZ, IDs, valores no finitos, completitud, geometría degenerada elemental y simetría/reflexión.
9. Existe al menos un caso conocido documentado; las expectativas geométricas se derivan analíticamente, no de copiar la salida de la implementación.
10. Todos los tests pasan en una versión MATLAB declarada, o cada incompatibilidad se documenta antes de aceptar la milestone.
11. README y documentos de convenciones coinciden con el código; no quedan constantes ni hipótesis físicas ocultas.
12. Una revisión de alcance confirma que no se ha introducido ninguna función de la lista “No incluido”.

## Después de v0.1

Las milestones posteriores se definirán una a una. Antes de cualquier solver se cerrarán las especificaciones matemáticas relevantes de `equations.md`, incluidos signos, restricciones, singularidades, tolerancias y casos de referencia. El orden previsto general es cinemática vertical, métricas geométricas, steering/actuación y después módulos de mayor nivel; no constituye aún un compromiso de implementación.

## Decisiones que bloquean v0.1

- Aprobar el origen del vehículo (`CS-001`).
- Aprobar la política de tolerancias (`CS-002`).
- Definir la forma exacta de la API (`DM-001`).
- Decidir si la procedencia inicial es por punto o por coordenada (`DM-003`).
- Determinar el dato mínimo de orientación de rueda si la representación 3D debe dibujar más que centro y contacto (`NM-003`).

