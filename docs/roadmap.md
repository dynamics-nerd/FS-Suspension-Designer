# Roadmap

## v0.1 — Static Double Wishbone Geometry

Estado: **implementada**, pendiente de cualquier limitación de ejecución indicada por el resultado real de la suite.

Incluye:

- una esquina `FL`, `FR`, `RL` o `RR`;
- ocho hardpoints canónicos;
- coordenadas internas en metros y entrada en m/mm;
- procedencia X/Y/Z;
- wheel center, contact patch y wheel axis;
- upright y conectividad estática mínimos;
- validador independiente con error IDs estables;
- consulta por ID sin exponer índices;
- vectores, distancias, unit vectors y cuatro métricas elementales;
- reflexión lateral pura;
- visualización 3D sin App Designer;
- persistencia MAT mínima con revalidación al cargar;
- ejemplo ficticio reproducible y tests automatizados.

No incluye movimiento ni ninguna métrica angular o dinámica.

### Criterios de aceptación v0.1

1. El constructor normaliza corner, IDs, unidades, procedencia y wheel axis.
2. La representación resultante satisface el schema documentado.
3. El validador cubre forma/tipo/finitud, IDs, prefijos, completitud, wheel axis y degeneraciones elementales.
4. La consulta pública se realiza por ID completo.
5. Reflexión y doble reflexión conservan los invariantes documentados.
6. Los casos analíticos verifican distancia y vector unitario explícitos.
7. El plot devuelve handles y respeta `axis equal` y los ejes X atrás/Y derecha/Z arriba.
8. La carga MAT revalida antes de devolver datos.
9. Los tests relevantes pasan en MATLAB R2025b, o la limitación de ejecución queda declarada sin sustituir MATLAB por otra herramienta.
10. No hay funcionalidad fuera de alcance.

## v0.2 — Bump Kinematics

Siguiente tarea prevista, **no iniciada**. Antes de codificarla deben especificarse wheel travel, constraints, upright pose, signos de camber, singularidades y casos conocidos.

## Fuera de alcance actual

Wheel travel, bump/rebound, heave, roll, pitch, steering, solver no lineal, upright pose en movimiento, camber, toe, caster, KPI, scrub, trail, instant centers, roll center, Ackermann, anti geometry, actuación, wheel rate, packaging, reglas, tire model, dinámica, Tilt Test, optimización, Adams y App Designer.

