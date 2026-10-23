# v0.21 — Guided full-vehicle static equilibrium

## Integration contract (defined before implementation)

GLOBAL_STATIC is VEHICLE scoped. It consumes registered FL/FR/RL/RR geometry,
actuation and coilover resources, four explicit native VerticalTireModels in
`inputs.tires`, and the existing concept mass/CG/dimension parameters. No mirrored
or rear geometry is generated implicitly. Existing parametric constructors accept
independent RL/RR; their explicit reference parameters remain required.

Plan fields: `vehicleOptions` (the native concept physical preparation contract),
`systemOptions` (native mass approximation, unsprung position assumption, road and
optional ride-height references), `cornerPlans` (FL/FR/RL/RR native MECHANICAL plans,
explicit zero wheel velocity), `initialGuesses` (7-by-N SI). Scenario `options`
contains the existing global solver budgets, bounds, scales and selection policy.
All physical inputs retain provenance. Missing quantities block readiness; no
illustrative defaults are supplied. Geometry frames must agree completely.

Preparation validates declarations without forward solves. Execution explicitly
solves BUMP and ACTUATION and evaluates MECHANICAL once per corner, builds the
native ACTUATION_BUMP_3D system and invokes solveGlobalStaticEquilibrium. Paths are
new evidence of this execution; no previous BUMP/MR ledger is silently consumed.
Payload contains `system` and `equilibrium`. Receipt reconstructs the four declared
MECHANICAL contexts against the stored sources, validates their complete native
evidence, reconstructs the system and validates the global result algebraically.
Receipt never runs a forward solver. Initial guesses/options are bound exactly.

GLOBAL_CONFIG installs a scenario, GLOBAL_RUN executes its ID. Both use the shared
operationBody execution/receipt contract and RF-01/02/03. Worker requests carry
configuration and no result history; the owner appends exact validated records.
Cancellation/epoch invalidation applies through the existing Controller.

## Dependencies and persistence

Context includes the four selected corner contexts (geometry/frame/origin binding,
actuation, coilover, architecture and numerical path plan), native vehicle/case
identities, four complete tires, system options, solver options and guesses.
Changing any consumed value makes evidence STALE without deleting it. Unrelated
resources and unrelated concept parameters do not invalidate it. Project revision
alone never implies physical difference. Existing logical schema0.16 and MAT0.19
remain; new fields are scenario data within the existing closed contract.

## Reused physics and limits

The authoritative equations, tolerances and algorithms are in
[global-static-equilibrium.md](global-static-equilibrium.md). Seven coordinates
are h, theta, phi and four body-relative bump coordinates; this is a static sampled
path approximation, not a seven-DOF dynamic vehicle. R=Rx(phi)*Ry(theta), SI,
+X rear/+Y right/+Z up. U=Ug+sum(Us)+sum(Ut); gradient(U)=0 with world force/moment
checks. Spring resistance uses signed dc/dz from the same PCHIP compression;
damper velocity is zero. Tire N=kt*max(0,roadZ-WCz+R0). Unsprung masses are included
in total mass, concentrated at moving WC; sprung CG is reconstructed accordingly.
No lateral tires, ARB, dynamics, aero, Tilt Test or tire performance model.

Convergence does not imply physical admissibility or stability. All attempts and
alternatives remain stored; NaN selection never produces a substituted nominal
pose. Stability is only the native local energy-Hessian criterion when available.
Root completeness is SUPPLIED_SEEDS_ONLY; no global uniqueness claim. No
extrapolation or crossing failed/disconnected segments. Search bounds are numerical,
not mechanical stops. Ride heights exist only at explicitly declared references.
Road is one horizontal plane. Production paths require fixed inboards/rack zero.

## Decisions

GSE-001: generate production paths within the explicitly requested global run,
rather than storing four recursively embedded EngineeringResults as dependencies.
This binds every source to the declared resources and avoids transporting ledgers.
Native standalone ideal paths remain test oracles, not a GUI feasibility shortcut.
GSE-002: use conceptPreparation for mass accounting instead of a second independent
vehicle mass editor/contract. Only consumed physical identities enter compatibility.
GSE-003: expose the existing global solver settings normalizer for pure readiness;
do not duplicate tolerances, solver equations or run a solve to validate inputs.
Historical motivations not recorded in the original contracts remain unknown.

Validation evidence and UI usage will be recorded in v0.21-validation.md.

## GUI use

1. Vehicle: declare mass convention, operating total/driver masses as applicable,
   wheelbase/tracks, CG XYZ and four unsprung masses. Values need availability and
   provenance. UNKNOWN remains missing. ZERO_UNSPRUNG_APPROXIMATION is a separate
   explicit global choice, not a silent replacement of missing values.
2. Geometry: select FL/FR/RL/RR independently (or explicitly declared FRONT
   symmetry) and apply/build the existing parametric definitions. No rear builder
   guesses station/track/radius. Actuation: configure each registered corner and
   its supported coilover, including source notes and known limits.
3. Global static / Configuration: inspect the resource matrix. Enter tire kt
   [N/mm], unloaded radius [mm], source KNOWN/ASSUMED/FIXED/DERIVED and note per
   corner. Enter monotone travel samples [mm] (at least three); GLOBAL_STATIC
   explicitly prescribes velocity zero. Defaults of the historical kinematic
   algorithm are used unless a recovered plan already declares its controls.
   The scenario selector also restores registered GLOBAL_STATIC declarations with
   IDs created through the public API; unapplied drafts block changing selection.
4. Declare gravity [m/s2] and source/note, operating configuration, contact policy
   CONCEPTUAL_HORIZONTAL or EXPLICIT with source/note. Conceptual references must
   be declared ASSUMED; explicit contacts use the four coordinate rows. These are
   nominal v0.9 comparison references, not additional constraints on global roots.
   Choose KNOWN_UNSPRUNG_MASSES or ZERO_UNSPRUNG_APPROXIMATION, position assumption
   UNSPRUNG_MASS_AT_WHEEL_CENTER, and road Z [mm]. No input is prefilled physically.
5. Supply bounds/scales and one or more seeds: row order h,theta,phi,zFL,zFR,zRL,zRR;
   translations/travel in mm, angles in degrees. Bounds are not stops. Mandatory
   numerical budgets use exact native SI names (N,Nm,m,rad,J); optional iteration,
   conditioning and selection controls may be blank for native algorithm defaults.
   UNIQUE_ONLY and LOWEST_ENERGY_STABLE have the different meanings described above.
   Optional ride-height reference IDs/points may be added/removed explicitly.
6. Apply and check readiness. A configuration may be registered but incomplete;
   diagnostics identify the missing data. Run global equilibrium only after READY.
   Existing execution selector offers explicit worker startup or synchronous mode
   if no process pool exists. Activity/cancellation follow Controller phases.
7. Results: select stored result and inspect its chosen or another found
   alternative. NONE clears all pose/force tables. Status, attempts, feasible path,
   native acceptance, stability and conditioning remain distinct. Tables contain
   pose, wheel/axle/side/cross loads, mechanical/tire compressions, WC world points,
   signed MR, spring forces, contact/limits, heights, energies and residuals. Full
   native attempt/solution diagnostics are retained in the evidence pane and MAT.
   Fs*MR is generalized resistance in the body-relative bump coordinate, not the
   tire's world-vertical normal force; separate table columns retain this distinction.
   Choose a reference result for normal-force and scalar pose/load/energy
   differences; its revision/state are displayed. Equal normals do not imply
   equivalent pose or configuration. Opening history never recomputes its physics.
   These differences are descriptive, not an objective score or a physical
   equivalence claim; energy comparisons require attention to ground/reference
   changes and to the native selection policy's domain of applicability.
8. Project Save/Open uses the existing native MAT workflow with exact full history.

### Pending native tires and refresh completion (V21-F-01)

A valid registered GLOBAL_STATIC scenario may contain an empty native tire
entry at any of FL/FR/RL/RR. Opening that scenario preserves its data exactly.
The presentation leaves all four editable tire fields blank for each empty
entry, retains the corner label and independently displays its travel samples.
Available tires still use the existing SI-to-N/mm/mm conversion and retain
their provenance. No zero, example tire or physical default is substituted.
Canonical readiness supplies `TIRE:<corner>:CONFIGURE_VERTICAL_TIRE`; Run stays
disabled while data are missing. The existing native table edits and Apply
complete the declaration and re-evaluate readiness. Apply continues to make
the existing native numerical solver defaults explicit; this correction adds
no defaults and changes neither readiness nor storage semantics.

`GlobalStaticView.refresh` commits its drawn-project marker only after rows,
readiness, resources, result evidence and final status render successfully.
An exception propagates normally and leaves the project eligible for a later
refresh. No catch simulates a successful render. Tests inject a transient final
status failure to verify retry with the identical project, as well as exercising
the native MAT/load/edit/Apply/run/save/load path. See
[focused correction evidence](v0.21-f01-validation.md).

Current integration requires left WC Y<0, right WC Y>0 and rear stations aft of
front stations in the same complete frame. Track/wheelbase concept references need
not be an exact footprint of the solved WC trajectory: actual points and moments
come from production geometry; this is why both v0.9 reference and global evidence
are retained instead of claiming physical equality.

## Selective dependency matrix

| Change | GLOBAL_STATIC evidence | Rationale |
|---|---|---|
| Any consumed corner geometry/frame/origin binding | STALE or readiness blocked | Different path/ownership |
| Actuation or coilover at any of four corners | STALE | Different compression/energy mapping |
| Tire stiffness/radius/provenance | STALE | Complete tire input retained |
| Operating mass, CG, consumed unsprung mass/dimensions | STALE | Vehicle identity/mass bookkeeping |
| Scenario ground/references, path grid, guesses, bounds/budgets/selection | STALE | Full declared operation/context |
| Consumed architecture or parametric-origin dependency | STALE/blocked | Native readiness contract |
| Unrelated concept quantity/resource/scenario, project description | REUSABLE_DEPENDENCIES | No change to consumed context |
| Ledger append only | CURRENT_EXECUTION if same configuration | Ledger excluded from configuration identity |

Snapshots retain provenance at execution; updating declarations never rewrites
the old result. Metadata not included in a native physical identity does not
authenticate a new measurement or execution. Native BUMP results do not record a
cryptographic history of algorithm execution; result validation proves stored
physical equations and exact declared operation, not unobservable clock/counters.
