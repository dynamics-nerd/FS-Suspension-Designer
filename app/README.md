# Application UI — Guided Design + v0.19 Packaging

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

