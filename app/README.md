# Application UI — Guided Design, Packaging, Actuation/Mechanics

## Tires (v0.22)

TiresView edits partial native resources and explicit laws, assigns immutable
revisions, configures studies and plots stored evidence. Definition/assignment/
study drafts are tracked separately and must be applied before Run/Save. Units
mm/degrees are presentation-only; stiffness N/rad is explicitly labelled. Global
static selects one vertical source, with library-derived tire cells readonly.
Optional MathWorks import/contrast remains a public API utility, not an MF/TTC
workflow in this view. [Contract](../docs/tire-models-foundation.md).

v0.21 adds the tenth **Global static** section (`GlobalStaticView`), with native
tables for four tires, sampled paths, gravity/provenance, mass approximation,
ground/reference points, seven-coordinate bounds/scales/seeds and solver controls.
Vehicle/Geometry/Actuation remain the editors of the existing resources. Apply
checks readiness; Run explicitly generates paths and calls the historical solver.
Stored attempts/alternatives, contacts, forces, pose, limits, residues, energies
and selected-result comparison show original revision and compatibility. NONE
shows no pose. mm/deg/N, internal SI; no implicit illustrative inputs or solves.
GLOBAL_CONFIG/GLOBAL_RUN use existing Controller, explicit worker/sync choice,
RF-01/02/03, bounded snapshots, cancellation, owner ledger and MAT.
[Detailed instructions](../docs/guided-global-static.md).

v0.20 adds `+fsdui/ActuationView.m` and pure table/plan/evidence adapters. The ninth
page exposes native actuation/coilover configuration, ACTUATION/MECHANICAL analysis,
fixed-suspension synthesis and exact resource adoption. New values display mm, deg,
N and N/mm; canonical values stay SI. Native configuration and adoption are public project
APIs, never calculations in callbacks. New operations use the same RF-01/02/03
receipt validation, epochs and complete owner ledger. Without a process worker,
Async offers an explicit worker/synchronous choice; no automatic fallback.
See [the v0.20 contract and use](../docs/guided-actuation-mechanics.md) and
[actual validation](../docs/v0.20-validation.md). No global visual redesign.

Launch from the repository: `app = launchFSSuspensionDesigner;`.
Edit with `appdesigner('app/FSSuspensionDesigner.m')` in MATLAB R2026b.
Keep the App Designer-generated XML companion. The native shell mounts dynamic
controls in `+fsdui/View.m`; `Controller.m` owns session and worker operations.
Callbacks collect presentation input and delegate engineering to public `fsd`
APIs. See [the complete guide](../docs/guided-design-interface.md).

Packaging adds an independent presentation class `+fsdui/PackagingView.m` and
explicit SI table adapters. Volumes, pairs, margins and point regions are drafts
until Apply. Static/stored-BUMP/seed/candidate operations call `fsd.project` and
`fsd.packaging`; they do not calculate engineering inside callbacks. Use the
existing process worker for long operations. The kernel stays sequential.
Lossless graph conversion yields UI callbacks before/after the process task;
it does not start backgroundPool. No engineering or MAT writing is delegated
to threads. Controller snapshots,
epochs, cancellation, reentry and single-writer guards apply across all phases.
The bounded native MAT storage is used for Packaging and all nonempty histories,
and restores exact logical values. Old v0.18 files remain readable; new history
files require the v0.19 loader. Always load through fsd.project.loadEngineeringProject.
Validation status/limits: [v0.19 record](../docs/v0.19-validation.md).

