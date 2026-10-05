# FS Suspension Designer — Agent Contract

- The project is written primarily in MATLAB. Do not add another language or service unless the task explicitly requires it and the change is approved.
- Engineering code belongs under `src/+fsd`; tests belong under `tests`; UI code belongs under `app`; theory and decisions belong under `docs`.
- Keep the engineering core independent of App Designer and any other UI. UI callbacks may validate presentation-level input and call the core, but must not contain engineering calculations.
- Implement only the requested scope. Do not make unrelated refactors or speculative implementations.
- Do not invent engineering equations, constants, tolerances, or physical assumptions. Document unresolved items as `OPEN DECISION`.
- Do not change coordinate, sign, unit, naming, or other physical conventions without explicit approval and corresponding documentation and tests.
- Use the canonical internal units and coordinate system documented in `docs/`. Convert units only at input/output boundaries.
- Distinguish known inputs from assumed inputs and document every assumption.
- When numerical behavior changes, add or update tests using a documented known case and an appropriate tolerance.
- Run the relevant MATLAB tests after changes. Report exactly what was run and clearly state any tests that could not be executed.
- Preserve module boundaries: kinematics and rules must not depend on one another; exporters must not perform kinematic calculations; tire models must remain replaceable behind a stable interface.

