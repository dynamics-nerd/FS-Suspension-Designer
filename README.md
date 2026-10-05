# FS Suspension Designer

FS Suspension Designer es una aplicación MATLAB en desarrollo para diseñar, sintetizar, optimizar y validar suspensiones de Formula Student. La arquitectura separa deliberadamente el núcleo matemático de la futura interfaz de MATLAB App Designer y de los adaptadores externos, como Adams Car.

## Estado actual

El repositorio contiene únicamente la **base técnica previa a v0.1**: estructura modular, convenciones, modelo de datos propuesto, contrato de desarrollo e infraestructura mínima de tests. Todavía no existe un modelo de hardpoints ejecutable ni un solver cinemático.

La siguiente milestone es **v0.1 — Static Double Wishbone Geometry**: una esquina double wishbone estática, validación de hardpoints y representación 3D básica.

## Tecnología y alcance

- MATLAB como lenguaje y núcleo matemático.
- Namespaces MATLAB bajo `src/+fsd`.
- MATLAB Unit Testing Framework.
- App Designer, Adams Car y los módulos avanzados están previstos, pero no implementados.

No están incluidos todavía bump/rebound, camber, toe, caster, KPI, roll center, steering, actuación, neumáticos, dinámica, optimización, normativa ni Tilt Test.

## Estructura

- `src/+fsd`: núcleo MATLAB, dividido por responsabilidades.
- `tests`: tests automatizados y plan de pruebas.
- `docs`: arquitectura, convenciones físicas, modelo de datos, ecuaciones pendientes y roadmap.
- `examples`: ejemplos reproducibles futuros.
- `data/rules`: datos normativos futuros, separados del código.
- `app`: futura interfaz App Designer; no contiene ingeniería.
- `output`: resultados generados localmente; no es fuente de verdad.

## Uso en MATLAB

1. Abra esta carpeta como carpeta actual de MATLAB.
2. Ejecute `setupProject` para añadir `src` al path durante la sesión.
3. Ejecute `runProjectTests` para lanzar todos los tests disponibles.

El runner restaura el path original al terminar. No requiere toolboxes aparte de MATLAB y su framework de testing incluido.

## Roadmap resumido

1. v0.1: geometría double wishbone estática.
2. Cinemática vertical y métricas geométricas, una vez aprobadas sus especificaciones matemáticas.
3. Steering y actuación.
4. Packaging, normativa, optimización y validación externa.

El alcance y los criterios de aceptación detallados están en [`docs/roadmap.md`](docs/roadmap.md).

## Aviso

**Proyecto en fase temprana. Los resultados no están validados y no deben utilizarse para fabricar, aprobar o declarar segura una suspensión real.** Toda salida futura deberá verificarse con casos conocidos, revisión de ingeniería y una herramienta de mayor fidelidad cuando corresponda.

