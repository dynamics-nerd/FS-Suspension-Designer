# Development register

This file owns status/planning only. Requirements, rationale, contracts and
execution evidence remain in their existing authoritative documents. Original
documents under original-requirements are historical and remain unedited.
Development validation does not imply independent audit acceptance.

Current state24October2026: user published v0.21.0 at362e92e. Older audit/status
entries retain their historical checkpoints. La auditoría independiente de v0.22
emitió CHANGES REQUIRED por V22-F-01/02/03 (MEDIUM); las correcciones posteriores
del desarrollador están validadas (112/112 seleccionados PASS), pendientes de
confirmación independiente.

| ID | Kind / status | Planned version / dependencies | Acceptance and references |
|---|---|---|---|
| FSD-020 | Feature / IMPLEMENTED, DEVELOPER VALIDATION PASS; independent audit pending | 0.20; native v0.7/v0.8/v0.15 and RF-03 | Guided configuration→analysis→synthesis→adoption→MAT;592 unique selected PASS (33 new/559 historical), [contract](guided-actuation-mechanics.md), [evidence](v0.20-validation.md); original §14 and FUNC-003/004 |
| FSD-021 | Feature / IMPLEMENTED; audit CHANGES REQUIRED for V21-F-01, correction validated by developer; independent re-audit pending | 0.21; FSD-020, native0.10, RF-01/02/03 |324 original developer-selected PASS (27 new/297 historical); audit358/358 PASS reported by user, one MEDIUM presentation finding; correction10/10 selected PASS; [integration contract](guided-global-static.md), [original evidence](v0.21-validation.md), [focused correction](v0.21-f01-validation.md) |
| V21-F-01 | Incident / MEDIUM; FIXED, DEVELOPER VALIDATION PASS; independent re-audit pending | 0.21; pending native tires and completed refresh |10/10 unique selected PASS (4 new/6 related), Analyzer0/4, actual Desktop controls; empty tire rows without invented data, completed-render marker, retry, READY and exact MAT; [focused evidence](v0.21-f01-validation.md) |
| FSD-022 | Feature / IMPLEMENTED; original audit CHANGES REQUIRED; corrections FIXED, DEVELOPER VALIDATION PASS; re-audit pending | 0.22; stable0.21 | Original161/161 retained; subsequent112/112 selected PASS (19 new/93 regressions), Analyzer0/708, DAG26; [contract](tire-models-foundation.md), [original evidence](v0.22-validation.md), [subsequent corrections](v0.22-audit-corrections.md) |
| V22-F-01 | Incident / MEDIUM; FIXED, DEVELOPER VALIDATION PASS; re-audit pending | 0.22; TIR-006 | Three canonical Desktop reproducers, default/reordered requests and incomplete plans; no silent scenario rewrite, Apply/Run/exact MAT |
| V22-F-02 | Incident / MEDIUM; FIXED, DEVELOPER VALIDATION PASS; re-audit pending | 0.22; TIR-007 | Structural consumption projection;8 focused cases and4 real-worker cases, complete historical identity, semantic rejection and vertical STALE retained |
| V22-F-03 | Incident / MEDIUM; FIXED, DEVELOPER VALIDATION PASS; re-audit pending | 0.22; TIR-008 |7 numeric cases PASS; safe integer/single to double, unsafe/logical rejection, canonical validation and exact MAT |
| TIR-001 | Decision / APPROVED | 0.22 | Native core and optional public MathWorks adapters; distinct variants, no compulsory add-on |
| TIR-002 | Physical contract / IMPLEMENTED, initial15 tests PASS | 0.22 | Explicit load/camber laws; no physical defaults for unknown inputs |
| TIR-003 | Integrity / IMPLEMENTED, DEVELOPER VALIDATION PASS | 0.22 | Immutable revisions/assignments, selective vertical context, real worker and exact MAT0.19/0.20/0.21/0.22; [evidence](v0.22-validation.md) |
| TIR-004 | Optional adapter / IMPLEMENTED,9/9 provider tests PASS | 0.22 | TIR import/contrast IMPORTED_UNVERIFIED through public APIs; no native family conversion/TTC fitting; native Desktop also tested with provider absent from path |
| TIR-005 | Limitation / DOCUMENTED | 0.22 | Stationary Fx/Fy, explicit domains, no Mz/effective radius/transients or experimental prediction |
| FSD-023 | Feature / PLANNED | 0.23; mechanics | ARB INTEGRATED/POST_DESIGN/DISABLED; ARB-001 in [decisions](decisions.md) |
| FSD-024 | Feature / PLANNED | 0.24; FSD-021/022/023 | Reduced performance and comparative event models; original §6, advanced lap-time/thermal models deferred |
| FSD-025 | Feature / PLANNED | 0.25; applicable physical models | Derived targets with explicit fidelity/adoption and synthesis feedback; original §5/8; FUNC-001/002/005 |
| FSD-DIRECT | Feature / DEFERRED, retained requirement | After 0.20, version OPEN | Real Direct Acting contract; no fictional rocker; original §9/25, ACS-007 |
| FSD-MOTION | Feature / OPEN | Native geometry | Vehicle pitch, combined states, side-view metrics, steering ratio and derivatives; original §12/13 |
| FSD-RULES | Feature / OPEN | Versioned selected ruleset and evidence | Rules Engine, no kinematics↔rules dependency; original §3; FUNC-006 |
| FSD-TILT | Feature / OPEN | Appropriate contact/static model | Preliminary and detailed tilt, separate inspection checklist; original §18; FUNC-006 |
| FSD-INTEGRAL | Feature / OPEN | Applicable targets/builders/evaluators | Joint synthesis and multiobjective comparison, original §15/16; FUNC-005 |
| FSD-ADAMS | Feature / DEFERRED | After engineering and final UI | Hardpoint export and validation plan before automated loop; original §20–22/27; FUNC-006 |
| FSD-021-TRACE | Integrity / IMPLEMENTED, DEVELOPER VALIDATION PASS | 0.21; RF-03 | Four paths generated at rest, shared operation reconstruction, dependency matrix, real worker4/4 and exact MAT0.21/0.20/0.19; no independent acceptance implied |
| FSD-021-UI01 | Incident / FIXED, UI TEST PASS | 0.21 | Native uitable rejects string inside mixed cell data; presentation converts text to char. Failed first run retained, second UI run3/3 PASS |
| FSD-021-NUM01 | Limitation / DOCUMENTED | 0.21; native0.10 | Narrow numerical box excludes some perturbed setups; explicit wider paths/box resolves preload case. Larger CG offset still no feasible residual decrease even with refined grid. No root-nonexistence claim or tolerance change; diagnostic MAT/logs in v0.21-validation.md |
| GSE-001 | Decision / ADOPTED | 0.21 | Generate production paths within explicit global run, no recursive parent ledgers; decisions.md |
| GSE-002 | Decision / ADOPTED | 0.21 | Existing concept mass accounting; no duplicate editable vehicle model |
| GSE-003 | Decision / ADOPTED | 0.21 | Public wrapper of existing solver settings for pure readiness |
| BUG-001 | Incident / NEEDS REPRODUCTION | Relevant input workflow | Historical Availability/value mismatch has no exact payload; retain unknown/KNOWN distinction, field-specific feedback |
| BUG-002 | Incident / IMPLEMENTED IN 0.20, dialog gestures not automated | 0.20 | Missing pool offers explicit Cancel/Start worker/Run synchronously; real process/sync paths verified; no silent fallback, [coverage limits](v0.20-validation.md) |
| UX-001 | Improvement / DEFERRED | Contextual need | Illustrative-input discovery; no general visual redesign |
| UX-002 | Improvement / IMPLEMENTED FOR ACTUATION FLOW | 0.20 | Visible native readiness and causes; UNSELECTED/MISSING distinct from declarations; UI PASS |
| UX-003 | Improvement / IMPLEMENTED FOR ACTUATION FLOW | 0.20 | Existing phase/activity/cancellation feedback; no fabricated percentage; actual process cancellation PASS |
| UX-004 | Improvement / IMPLEMENTED FOR NEW VIEWS | 0.20 | mm, deg, N and N/mm where appropriate; SI data unchanged; numerical/graphics boundary PASS |
| UX-005 | Improvement / IMPLEMENTED FOR ACTUATION FLOW | 0.20 | Result/revision/current compatibility and diagnostics; native technical states retained; selective STALE PASS |
| PERF-001 | Investigation / OPEN, not demonstrated regression | Representative measurement only | Historical single 18.513s FRONT BUMP is not a benchmark or universal acceptance threshold |
| FSD-020-UI01 | Incident / RESOLVED IN DEVELOPMENT | 0.20; minimal UI | Empty nested configuration page/timeouts replaced by explicit selector/panels; real table gestures PASS, [evidence](v0.20-validation.md) |
| FSD-020-UI02 | Incident / RESOLVED IN DEVELOPMENT | 0.20; evidence selection | Invalid selection clears diagnostics/curves/pose and render key; prior valid selection redraws; real UI test PASS, [evidence](v0.20-validation.md) |
| FSD-020-MAT01 | Verification / PASS | 0.20; native storage0.19 | Authentic release0.19 MECHANICAL MAT read/exact/resaved; worker synthesis/adoption/complete MAT verified, [evidence](v0.20-validation.md) |
| FSD-020-DOC01 | Requirement / ONGOING | Every future version | REQ-DOC-CONTINUITY; unknown historical reasons pending reconstruction, new GAM decisions documented in [decisions](decisions.md) |

Historical BUG/UX/PERF/FUNC identifiers refer to
[the manual v0.19 register](original-requirements/FS_Suspension_Designer_v019_Registro_Incidencias_y_Mejoras.md).
Closed entries require version, reproducible case, actual outcome and evidence;
independent acceptance is tracked separately. New open decisions receive stable
IDs and link to decisions.md instead of duplicating rationale here.
