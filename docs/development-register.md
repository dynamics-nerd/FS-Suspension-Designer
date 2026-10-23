# Development register

This file owns status/planning only. Requirements, rationale, contracts and
execution evidence remain in their existing authoritative documents. Original
documents under original-requirements are historical and remain unedited.
Development validation does not imply independent audit acceptance.

| ID | Kind / status | Planned version / dependencies | Acceptance and references |
|---|---|---|---|
| FSD-020 | Feature / IMPLEMENTED, DEVELOPER VALIDATION PASS; independent audit pending | 0.20; native v0.7/v0.8/v0.15 and RF-03 | Guided configuration→analysis→synthesis→adoption→MAT;592 unique selected PASS (33 new/559 historical), [contract](guided-actuation-mechanics.md), [evidence](v0.20-validation.md); original §14 and FUNC-003/004 |
| FSD-021 | Feature / PLANNED | 0.21; FSD-020 | Four-corner/global equilibrium workflow; [existing contract](global-static-equilibrium.md) |
| FSD-022 | Feature / PLANNED | 0.22 | Geometry Only/Generic/Custom; original §7; force data optional; equations/assumed parameter sources OPEN DECISION at specification |
| FSD-023 | Feature / PLANNED | 0.23; mechanics | ARB INTEGRATED/POST_DESIGN/DISABLED; ARB-001 in [decisions](decisions.md) |
| FSD-024 | Feature / PLANNED | 0.24; FSD-021/022/023 | Reduced performance and comparative event models; original §6, advanced lap-time/thermal models deferred |
| FSD-025 | Feature / PLANNED | 0.25; applicable physical models | Derived targets with explicit fidelity/adoption and synthesis feedback; original §5/8; FUNC-001/002/005 |
| FSD-DIRECT | Feature / DEFERRED, retained requirement | After 0.20, version OPEN | Real Direct Acting contract; no fictional rocker; original §9/25, ACS-007 |
| FSD-MOTION | Feature / OPEN | Native geometry | Vehicle pitch, combined states, side-view metrics, steering ratio and derivatives; original §12/13 |
| FSD-RULES | Feature / OPEN | Versioned selected ruleset and evidence | Rules Engine, no kinematics↔rules dependency; original §3; FUNC-006 |
| FSD-TILT | Feature / OPEN | Appropriate contact/static model | Preliminary and detailed tilt, separate inspection checklist; original §18; FUNC-006 |
| FSD-INTEGRAL | Feature / OPEN | Applicable targets/builders/evaluators | Joint synthesis and multiobjective comparison, original §15/16; FUNC-005 |
| FSD-ADAMS | Feature / DEFERRED | After engineering and final UI | Hardpoint export and validation plan before automated loop; original §20–22/27; FUNC-006 |
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
