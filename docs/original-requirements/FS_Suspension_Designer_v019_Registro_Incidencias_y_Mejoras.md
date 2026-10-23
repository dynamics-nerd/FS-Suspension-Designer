# FS Suspension Designer v0.19 — Registro de incidencias y mejoras

**Proyecto:** C - App Dinámica  
**Aplicación evaluada:** FS Suspension Designer v0.19  
**Origen:** pruebas manuales y observaciones recogidas en la conversación «Auditoria App»  
**Fecha de consolidación:** 2026-10-18  
**Tipo de documento:** registro de auditoría funcional preliminar

> [!IMPORTANT]
> Este registro documenta únicamente las observaciones y resultados comunicados durante las pruebas manuales de v0.19. No acredita la precisión física de los modelos, la corrección científica de los resultados, la cobertura completa de la aplicación ni la ausencia de otros defectos. Cuando no se dispone de captura, log, configuración o resultado exportado, se indica expresamente.

## 1. Convenciones

### 1.1 Tipos

| Prefijo | Tipo | Uso |
|---|---|---|
| `BUG` | Bug | Fallo funcional o incoherencia de datos observada. |
| `UX` | Experiencia de usuario | Problema de descubribilidad, claridad, feedback o presentación. |
| `PERF` | Rendimiento | Tiempo de ejecución que requiere medición y análisis. |
| `FUNC` | Funcionalidad pendiente | Capacidad necesaria para el flujo objetivo que no consta como integrada. |

### 1.2 Gravedad y prioridad

| Nivel | Gravedad | Prioridad |
|---|---|---|
| Crítica / P0 | Bloquea el uso general o compromete datos/resultados de forma grave. | Intervención inmediata. |
| Alta / P1 | Bloquea un flujo principal o una capacidad esencial. | Próxima fase de desarrollo. |
| Media / P2 | Dificulta el uso, provoca errores evitables o limita un flujo secundario. | Planificar tras los bloqueos P1. |
| Baja / P3 | Mejora de claridad, comodidad o acabado. | Incorporar cuando encaje en la planificación. |

### 1.3 Estados

- **Pendiente:** no se ha documentado una solución ni workaround válido.
- **Workaround disponible:** el flujo puede continuar mediante una acción manual; la causa o solución definitiva sigue pendiente.
- **Indagación:** hay una observación inicial, pero faltan mediciones o diagnóstico para clasificarla como defecto.
- **Funcionalidad pendiente:** capacidad solicitada que no consta como implementada/integrada en el flujo probado.

## 2. Resumen de incidencias

| ID | Tipo | Resumen | Gravedad | Prioridad | Estado |
|---|---|---|---|---|---|
| BUG-001 | Bug | `Availability/value mismatch; unknown is not zero` al aplicar Vehicle | Alta | P1 | Pendiente; causa exacta no confirmada |
| BUG-002 | Bug / configuración | Modo asíncrono habilitado sin *process worker* iniciado | Alta | P1 | Workaround disponible: desmarcar la casilla |
| UX-001 | UX | `Illustrative inputs` solo está disponible en Project | Media | P2 | Pendiente |
| UX-002 | UX | El estado `READY` queda escondido dentro del JSON | Media | P2 | Pendiente |
| UX-003 | UX | No hay *spinner* ni progreso visible durante cálculos | Media | P2 | Pendiente |
| UX-004 | UX | Gráficos en radianes y metros en vez de grados y milímetros | Media | P2 | Pendiente |
| UX-005 | UX | Etiquetas técnicas de compatibilidad poco claras | Media | P2 | Pendiente |
| PERF-001 | Rendimiento | BUMP FRONT con 3 muestras tardó 18,513 s | Media | P2 | Indagación; umbral aceptable no definido |
| FUNC-001 | Funcionalidad pendiente | Generación de targets desde datos básicos del vehículo y objetivos de rendimiento | Alta | P1 | Funcionalidad pendiente |
| FUNC-002 | Funcionalidad pendiente | Simulaciones Skidpad, Acceleration, Autocross y Endurance | Alta | P1 | Funcionalidad pendiente |
| FUNC-003 | Funcionalidad pendiente | Arquitectura pushrod y elección de anclaje en upright/UCA/LCA | Alta | P1 | Funcionalidad pendiente |
| FUNC-004 | Funcionalidad pendiente | Integración gráfica de rocker y motion ratio | Alta | P1 | Funcionalidad pendiente |
| FUNC-005 | Funcionalidad pendiente | Síntesis integral desde targets hasta geometrías candidatas | Alta | P1 | Funcionalidad pendiente |
| FUNC-006 | Funcionalidad pendiente | Rules, Tilt Test y Adams | Media | P2 | Funcionalidad pendiente |

## 3. Incidencias detalladas

### BUG-001 — Incoherencia entre Availability y valor de Vehicle

| Campo | Detalle |
|---|---|
| Tipo | Bug de validación/coherencia de datos |
| Gravedad / prioridad | Alta / P1 |
| Estado | Pendiente; la causa exacta aún no está confirmada |
| Mensaje observado | `Availability/value mismatch; unknown is not zero` |
| Contexto | Aplicación de datos de Vehicle con valores conocidos mientras `Availability=NOT_PROVIDED`. |

**Pasos de reproducción conocidos**

1. Abrir o preparar un Vehicle con algunos campos que contienen valores conocidos.
2. Mantener esos mismos campos, o su metadato asociado, con `Availability=NOT_PROVIDED`.
3. Ejecutar la acción de aplicar Vehicle.
4. Observar el rechazo y el mensaje indicado.

**Comportamiento observado**

La aplicación detecta una incompatibilidad entre el valor aportado y su estado de disponibilidad. El flujo no continúa con esa combinación.

**Comportamiento esperado**

La interfaz debe mantener valor y disponibilidad coherentes antes de enviar los datos. Si existe un valor conocido, su disponibilidad no debería permanecer como `NOT_PROVIDED`. Si el usuario genera una combinación inválida, el mensaje debería identificar el campo afectado y explicar cómo corregirlo.

**Propuesta concreta**

- Sincronizar automáticamente `Availability` al introducir, importar o conservar un valor conocido.
- Alternativamente, bloquear la acción de aplicar y mostrar validación por campo antes del envío.
- Incluir en el error el identificador del campo, el valor recibido y la transición permitida, sin exponer información interna innecesaria.
- Añadir pruebas para valores conocidos, cero válido, valor desconocido, importación parcial y cambio manual de disponibilidad.

**Evidencia disponible**

- Mensaje textual registrado durante la prueba manual.
- Condición reportada: valores conocidos combinados con `Availability=NOT_PROVIDED`.
- No se adjuntaron log completo, captura, payload ni campo exacto; por ello no se atribuye todavía una causa interna.

---

### BUG-002 — Modo asíncrono activo sin process worker

| Campo | Detalle |
|---|---|
| Tipo | Bug de configuración/operación y UX de estado |
| Gravedad / prioridad | Alta / P1 |
| Estado | Workaround disponible; solución definitiva pendiente |
| Workaround confirmado | Desmarcar la casilla de modo asíncrono. |

**Pasos de reproducción conocidos**

1. Habilitar la casilla de ejecución asíncrona.
2. No iniciar o no disponer de un *process worker* activo.
3. Lanzar una operación que dependa de dicho worker.
4. Observar que la operación no progresa correctamente.

**Comportamiento observado**

El modo asíncrono puede quedar habilitado aunque no haya un worker iniciado. La prueba pudo continuar al desmarcar la casilla y usar el modo no asíncrono.

**Comportamiento esperado**

La aplicación debería detectar la disponibilidad real del worker. Si no está operativo, debería impedir activar el modo asíncrono, ofrecer iniciarlo o cambiar automáticamente a ejecución local/síncrona con un aviso claro.

**Propuesta concreta**

- Añadir comprobación de salud del worker al cargar la pantalla y antes de lanzar cada trabajo.
- Mostrar estados comprensibles: `Worker disponible`, `Worker no iniciado` y `Ejecución síncrona`.
- Deshabilitar la casilla cuando el backend asíncrono no esté disponible.
- Evitar esperas indefinidas mediante timeout y recuperación controlada.

**Evidencia disponible**

- Observación manual de que el modo asíncrono estaba habilitado sin worker.
- Workaround confirmado: desmarcar la casilla permitió continuar.
- No se adjuntaron logs del worker ni detalles de despliegue.

---

### UX-001 — Illustrative inputs solo en Project

**Pasos de reproducción conocidos:** navegar por el flujo fuera de Project y buscar la acción `Illustrative inputs`; comprobar que solo aparece en Project.

**Observado:** la ayuda para cargar datos ilustrativos queda ligada a una ubicación concreta y puede no descubrirse cuando se necesita en otros pasos.

**Esperado:** acceso contextual y consistente desde las pantallas en las que esos datos sean útiles, o una indicación visible que dirija al usuario a Project.

**Propuesta:** añadir una acción contextual reutilizable o un enlace `Cargar ejemplo desde Project`; aclarar si reemplaza, combina o conserva datos existentes.

**Evidencia:** observación manual registrada; sin captura adjunta.

---

### UX-002 — Estado READY escondido en JSON

**Pasos de reproducción conocidos:** ejecutar el flujo de READINESS y consultar la salida mostrada.

**Observado:** el resultado `READY` existe, pero queda dentro de la representación JSON.

**Esperado:** estado principal visible en la interfaz sin que el usuario tenga que interpretar datos técnicos.

**Propuesta:** mostrar una insignia de estado (`READY`, `NOT READY`, `ERROR`) con resumen de causas y mantener el JSON como detalle expandible.

**Evidencia:** READINESS devolvió `READY` en la prueba manual; no se adjuntó el JSON completo.

---

### UX-003 — Sin spinner o progreso visible

**Pasos de reproducción conocidos:** iniciar BUILD o BUMP y esperar su finalización.

**Observado:** durante el cálculo no se muestra un indicador claro de actividad o avance.

**Esperado:** feedback inmediato que confirme que el trabajo fue aceptado, continúa activo y no ha bloqueado la interfaz.

**Propuesta:** incorporar *spinner* inicial, fase actual, tiempo transcurrido y, cuando exista información suficiente, progreso determinado. Añadir cancelación segura para operaciones largas.

**Evidencia:** observación manual durante ejecuciones con tiempos medibles; sin grabación adjunta.

---

### UX-004 — Unidades de gráficos poco adecuadas para ingeniería de suspensión

**Pasos de reproducción conocidos:** ejecutar BUMP, abrir las curvas y revisar ejes/valores.

**Observado:** se muestran ángulos en radianes y desplazamientos en metros.

**Esperado:** presentación por defecto en grados y milímetros, manteniendo conversiones consistentes y unidades inequívocas en ejes, tooltips y exportaciones.

**Propuesta:** usar grados y milímetros como unidades de visualización predeterminadas; conservar SI internamente si corresponde; añadir selector de unidades y pruebas de conversión. No alterar los datos físicos al cambiar su representación.

**Evidencia:** las curvas se actualizaron y se solicitó expresamente presentarlas en grados en lugar de radianes; también se registró la preferencia por milímetros frente a metros.

---

### UX-005 — Etiquetas técnicas de compatibilidad poco claras

**Pasos de reproducción conocidos:** recorrer las opciones o estados de compatibilidad mostrados durante la preparación/ejecución del flujo.

**Observado:** las etiquetas técnicas no explican suficientemente qué significa cada compatibilidad ni qué debe hacer el usuario.

**Esperado:** terminología orientada a decisión, con explicación breve, causa y acción recomendada.

**Propuesta:** sustituir o complementar códigos internos con nombres legibles, tooltips, leyenda y mensajes accionables; conservar el identificador técnico en un panel de detalles.

**Evidencia:** observación cualitativa de la prueba manual; no se documentaron las cadenas exactas, por lo que deben inventariarse antes de rediseñarlas.

## 4. Indagación de rendimiento

### PERF-001 — Coste de BUMP FRONT con 3 muestras

| Campo | Detalle |
|---|---|
| Tipo | Rendimiento |
| Gravedad / prioridad provisional | Media / P2 |
| Estado | Indagación; no clasificado como regresión ni fallo |
| Medición registrada | 18,513 s |
| Configuración conocida | BUMP, eje FRONT, 3 muestras |

**Pasos de reproducción conocidos**

1. Preparar un caso capaz de ejecutar BUMP.
2. Configurar FRONT con 3 muestras.
3. Lanzar el cálculo y medir hasta la finalización.

**Comportamiento observado**

La ejecución comunicada tardó 18,513 s. El cálculo convergió al menos para FL y las curvas se actualizaron.

**Comportamiento esperado**

Todavía no existe un umbral de aceptación documentado. Antes de declarar un problema, debe definirse el presupuesto de tiempo por tipo de equipo, configuración y número de muestras.

**Propuesta concreta de indagación**

- Repetir varias ejecuciones distinguiendo primera ejecución de ejecuciones en caliente.
- Registrar hardware, versión, configuración completa, backend, modo síncrono/asíncrono y tiempos por fase.
- Medir escalado con número de muestras y por esquina/eje.
- Perfilar preparación, solver, serialización y renderizado de curvas por separado.
- Definir objetivo de UX: feedback inmediato, tiempo típico y timeout controlado.

**Evidencia y límites**

- Única medición manual comunicada: 18,513 s.
- No constan repeticiones, hardware, dispersión, línea base ni perfil; no se afirma que el tiempo sea anómalo.

## 5. Funcionalidades pendientes prioritarias

### FUNC-001 — Generación de targets desde datos básicos y rendimiento

**Necesidad:** permitir partir de datos parciales/básicos del coche, ejecutar análisis y obtener targets de suspensión comparables para seleccionar los que ofrezcan el rendimiento deseado.

**Flujo esperado:** datos disponibles y su incertidumbre → escenarios/objetivos de rendimiento → simulaciones → targets candidatos → comparación y selección → envío de targets a la búsqueda de geometrías.

**Propuesta concreta:** crear un asistente de definición de escenario que distinga dato conocido, supuesto, rango y dato ausente; generar targets con trazabilidad al escenario; permitir comparar alternativas y aprobar explícitamente el conjunto que alimentará la síntesis geométrica.

**Criterio mínimo de aceptación:** un usuario puede completar el flujo con datos parciales sin introducir incoherencias de disponibilidad, conoce qué supuestos se han usado y puede transferir un conjunto versionado de targets a Geometry.

### FUNC-002 — Simulaciones dinámicas por prueba

**Necesidad:** incorporar escenarios de Skidpad, Acceleration, Autocross y Endurance para relacionar decisiones de suspensión con objetivos de rendimiento.

**Propuesta concreta:** definir entradas, salidas, supuestos, métricas y nivel de fidelidad de cada evento; reutilizar un modelo de vehículo común; mostrar comparaciones y sensibilidad sin presentar los resultados como físicamente validados hasta completar correlación y verificación.

**Criterio mínimo de aceptación:** cada evento produce métricas y targets trazables, declara sus supuestos y puede compararse bajo configuraciones reproducibles.

### FUNC-003 — Arquitectura pushrod y puntos de anclaje

**Necesidad:** integrar la pushrod en la generación/búsqueda de geometría y permitir elegir el anclaje en upright (mangueta), UCA (brazo superior) o LCA (brazo inferior), sujeto a las restricciones del modelo.

**Propuesta concreta:** modelar el tipo de arquitectura, punto de anclaje, restricciones espaciales y cinemáticas; validar interferencias y factibilidad; incluir estos parámetros en la optimización y en la exportación de geometría.

**Criterio mínimo de aceptación:** la configuración conserva la elección de anclaje, la representa geométricamente, participa en el cálculo y produce mensajes claros cuando una opción no es factible.

### FUNC-004 — Rocker y motion ratio integrados gráficamente

**Necesidad:** representar e integrar rocker y motion ratio (MR) dentro del mismo flujo de arquitectura pushrod.

**Propuesta concreta:** añadir puntos/ejes del rocker, conexión con pushrod y amortiguador, curva de MR frente a recorrido y restricciones; actualizar la vista gráfica con cada cambio y enlazar los resultados a cargas/recorridos relevantes.

**Criterio mínimo de aceptación:** la vista y las curvas reflejan la arquitectura configurada, con unidades claras y trazabilidad entre geometría, recorrido y MR.

### FUNC-005 — Síntesis integral

**Necesidad:** cerrar el ciclo entre datos del coche, simulaciones, targets elegidos y búsqueda de geometrías, evitando pasos manuales opacos o desconectados.

**Propuesta concreta:** establecer un pipeline versionado con entradas, supuestos, resultados, selección de targets, restricciones de empaquetado, arquitectura y ranking de geometrías; permitir volver a una etapa sin perder trazabilidad.

**Criterio mínimo de aceptación:** desde un proyecto reproducible se puede identificar qué datos y targets originaron cada geometría candidata y por qué fue clasificada de una determinada manera.

### FUNC-006 — Rules, Tilt Test y Adams

**Necesidad:** integrar comprobaciones reglamentarias, soporte del Tilt Test e interoperabilidad o flujo definido con Adams.

**Propuesta concreta:** separar claramente: (a) reglas y versión del reglamento, (b) cálculo/procedimiento de Tilt Test con entradas y márgenes, y (c) exportación/importación hacia Adams con esquema y validación. Versionar reglas y formatos externos.

**Criterio mínimo de aceptación:** cada comprobación indica versión, entradas, resultado y causa; los intercambios con Adams son reproducibles y detectan datos incompatibles.

## 6. Resultados manuales que sí pasaron

| Prueba | Resultado observado | Alcance y cautelas |
|---|---|---|
| READINESS | `READY` | El estado se obtuvo, aunque quedó escondido en JSON. No equivale a validar todos los módulos. |
| BUILD nominal | `VALID` en 4,601 s | Confirma una ejecución nominal concreta. No consta batería de casos límite ni repetición estadística. |
| BUMP ±30 mm | Convergió al menos para FL | No consta confirmación equivalente para todas las esquinas ni validación física del resultado. |
| Actualización de curvas | Las curvas se actualizaron | La actualización visual funcionó en el caso probado; queda pendiente mejorar las unidades mostradas. |

## 7. Evidencia pendiente de conservar en futuras pruebas

Para convertir estas observaciones en incidencias plenamente reproducibles, adjuntar en próximas sesiones:

- identificador de build/commit y entorno de ejecución;
- proyecto o caso mínimo reproducible, sin datos sensibles;
- payload de entrada y metadatos `Availability` relevantes;
- logs de aplicación, solver y worker con marcas de tiempo;
- capturas o grabación de la interfaz;
- configuración exacta de BUILD/BUMP, esquina, recorrido y muestras;
- resultados exportados y tiempos de varias repeticiones;
- hardware y modo de ejecución;
- resultado esperado con tolerancias justificadas cuando exista referencia física.

## 8. Orden de trabajo sugerido

1. **Estabilizar entradas y ejecución:** BUG-001 y BUG-002.
2. **Cerrar el feedback básico del flujo:** UX-002, UX-003 y UX-004.
3. **Construir el flujo de valor principal:** FUNC-001, FUNC-002 y FUNC-005.
4. **Completar la arquitectura de suspensión:** FUNC-003 y FUNC-004.
5. **Medir y optimizar con una línea base:** PERF-001.
6. **Mejorar descubribilidad y lenguaje:** UX-001 y UX-005.
7. **Añadir validaciones e interoperabilidad ampliadas:** FUNC-006.

## 9. Criterio de cierre del registro

Una incidencia no debe marcarse como resuelta únicamente porque exista un workaround. Para cerrarla, registrar como mínimo:

- versión en la que se corrige o implementa;
- cambio realizado;
- caso de prueba reproducible;
- resultado antes/después;
- evidencia adjunta;
- posibles regresiones verificadas;
- responsable y fecha de validación.

La validación de software y la validación física deben mantenerse separadas: que el cálculo termine, converja o actualice una curva no demuestra por sí solo que el modelo represente correctamente el vehículo real.
