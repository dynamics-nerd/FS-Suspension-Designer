# v0.18 — Guided Suspension Design Interface

## v0.19 Packaging extension

The native R2026b app gains an eighth Packaging page. The App Designer shell is
retained; dynamic layout is editable in `app/+fsdui/PackagingView.m`. This page
does not create physical dimensions from the concept or kinematic hardpoints.

1. Load/build an existing geometry. Choose the corner on Packaging.
2. Add volumes, pairs and point regions; every dimension, source, fidelity,
   revision, transform and margin must be explicit. Tables scroll horizontally.
   Choose Volumes/Pairs/Regions from the editor selector. Lengths are metres,
   rotation entries are the nine columns of a proper R. Circular dimension1 is
   radius, or explicitly prefix `D:` to enter a diameter; stored output is radius.
   SEGMENT uses two canonical point IDs and only a radius, with identity T.
   Imported frames are preserved for existing IDs. New/renamed IDs in a definition
   containing incompatible frames require explicit core-API declarations: an ID
   edit never silently reinterprets their coordinates in the selected corner frame.
3. Apply definitions. Invalid drafts are not partially committed. Alternatively,
   explicitly confirm Illustrative solids to load the labelled software fixture;
   its numbers are not recommended vehicle dimensions.
4. Run nominal. For sampled motion, run BUMP on Analysis first, then select its
   stored parent on Packaging and Check stored BUMP. This action never solves BUMP.
5. Select an actual pair check to highlight both declared components and show
   its sample. Separated witnesses are shown only when provided by the kernel.
   Sample dropdown changes the stored pose, not the model. Filters select issues
   or clear checks; the worst observed pair margin is initially selected. Point
   region violations are listed separately with their sample indices. Scroll the
   page vertically on small displays; the 3D viewport keeps a useful fixed height.
6. Change a solid or margin and Apply: historical packaging remains visible as
   STALE while unchanged BUMP is reusable. Rerun explicitly for new evidence.
7. Select compatible corner/axle synthesis evidence and an actual candidate index;
   Compare seed + index consumes their stored BUMP sources. History/compare shows
   original score alongside packaging, never a new combined objective or ranking.
   Choose Pair checks/Point regions/History from the evidence selector.
8. Save/reopen through Project's trusted native MAT workflow. Old projects have
   no inferred packaging resources. Use the existing process worker for long
   operations; navigation remains independent of the numerical worker snapshot.

v0.19 transport has three observable stages: ENCODING and DECODING perform only
lossless plain-data conversion cooperatively; EXECUTING runs engineering and
file operations on the existing ProcessPool. No solver runs on a thread.
Conversion dispatches navigation/edit/cancellation callbacks every256 visits or
nodes, under the completion and single-writer guards. It does not start the
global backgroundPool: a measured trivial background task added about1.1GiB to
the owned runtime footprint before any engineering calculation. No shared pool
or global computational-thread setting is modified. A process Future exists
only in EXECUTING; the codec input is released on transition/finish. Read
completed values through Controller.LastValue, not internal Future outputs.
Idle shutdown breaks the Packaging callbacks back to the main View and releases
closed-view project/result/control references. It is idempotent and leaves any
external immutable snapshots unchanged; borrowed worker work is still protected
by Controller.close. A closed View is not an active Controller session.

F-02 uses FSD_VALUE_GRAPH_V1 for that lossless conversion. Unrelated ledger
records are retained at the owner instead of sent/returned for every update.
Returned deltas are validated and merged without discarding history; epochs
are checked again after the merge. SAVE/VALIDATE/COMPATIBILITY return no project
copy. The previous FSD_TEXT_V1 MAT development files remain readable.

The cooperative scheduling quantum applies to graph conversion, not to every
canonical validator or the owner's final history merge. Those synchronous
sections, and actual rendering, can still delay callbacks. Navigation demonstrated
in EXECUTING/DECODING is not a guarantee of continuous responsiveness throughout
the entire operation. The correction record distinguishes measured wall time,
worker-adapter time, pool startup and observed callback gaps; these are not
interchangeable engineering-calculation times.

Packaging and all nonempty histories use a versioned native storage envelope
with one ledger variable per record and a reversible value graph. Old MAT files
remain readable; empty non-Packaging projects retain the old writer. Newly
written history files require v0.19. Use fsd.project.loadEngineeringProject
rather than raw envelope.project access for these files. See data-model
and the validation record for memory/performance evidence and remaining limits.

F-01 selection is keyed by result/project/revision, pair ID and actual sample,
not a row number. A filter explicitly reconciles both the native selection and
the stored pose even when another click emits no event. If a selected check is
hidden, the first visible check is explicitly chosen; an empty filter has no
pair selection. A manual sample with no visible check clears the highlight.
The status area identifies the selected result/pair/sample separately from the
aggregate classification. Replacing a project/result clears an obsolete pose.

Statuses are not certification: CLEAR_SAMPLED checks only declared simplified
solids/pairs/regions and resolved requested samples. Missing dimensions/poses
prevent CLEAR; failed source states are not reconstructed or interpolated.
ROLL/RACK sweeps, actuation mobile solids, CAD, manufacturing approval and combined
motion are outside this first integrated adapter. See the
[complete packaging contract](packaging-physical-feasibility.md) and
[actual validation evidence](v0.19-validation.md).

## Runtime and launch

MATLAB R2026b / Windows 11. From the repository folder run:

Use an ordinary MATLAB Desktop session for the interactive app. `-batch` is
appropriate for automated tests, not a substitute for Desktop visual acceptance:
the observed batch CEF helper deferred tab contents until real navigation.

```matlab
app = launchFSSuspensionDesigner;
```

After opening the app, the workflow uses buttons, tables and file dialogs; no
MATLAB commands are required. To edit the authentic App Designer shell:

```matlab
appdesigner(fullfile(pwd,'app','FSSuspensionDesigner.m'));
```

Recommended desktop size:1100×760 or larger. Tables retain native scrolling;
the synthesis layout scrolls vertically and result plots share the available space.

Keep `FSSuspensionDesigner.m` and `FSSuspensionDesigner.xml` together. They were
created and saved by R2026b App Designer, not by an undocumented XML writer.
`matlab.apps.App` / `AppConfigFilename` are the native text-format runtime.
The native startup callback mounts the reusable programmatic `fsdui.View`.
Thus Design View edits the shell; the dynamic workflow layout is maintained in
`app/+fsdui/View.m`, not visually represented as hundreds of shell components.
Callbacks contain no engineering equations. This hybrid is intentional and does
not claim that every dynamically created table is editable in Design View.

Official format documentation:
[App Designer File Formats](https://www.mathworks.com/help/matlab/creating_guis/app-designer-file-formats.html),
[App Designer](https://www.mathworks.com/help/matlab/ref/appdesigner.html).
External startup edits produced a normalization warning whose native comparison
showed no code differences. App Designer then reopened, normalized and saved
the file, retaining all startup statements; subsequent reopening was clean.
Metadata version was edited and saved through the native editor. Keep its native
formatting and CRLF working-copy line endings; do not hand-edit the XML.

## Layer boundaries

- `src/+fsd`: existing value contracts, construction, kinematics, assessment,
  deterministic search, revisions and native MAT envelope.
- `app/+fsdui/perform`: value-only operation adapter invoking those public APIs.
- `app/+fsdui/Controller`: session ownership, operation IDs/epochs, one in-flight
  operation, explicit adoption, save publication and resource lifetime.
- `app/+fsdui/View`: native controls, editable draft tables, navigation and plots
  of stored sources. No callback closes suspension constraints or optimizes.

Core physical modules never import the app package. Only the software-version
eligibility list in `validateEngineeringResult` expands to accept0.18; physical
schemas, equations, solvers, tolerances and search controller are unchanged.
Historical0.16/0.17 EngineeringResults remain accepted. Construction retains its
0.17 schema. The original0.18 UI wrote the0.16 MAT envelope; the0.19 audit
correction now writes bounded0.19 storage for any project with results, even
without Packaging. Legacy0.16/0.18 files remain readable. Empty non-Packaging
projects retain the legacy writer; new history files require the0.19 loader.

## Inputs and units

Canonical SI and the AUDITED axes remain unchanged: +X rearward, +Y rightward,
+Z upward; positive toe-in and native signed camber. Tables explicitly display
m, rad, kg and dimensionless quantities. This first UI uses canonical units;
it does not silently reinterpret user input as mm/degrees.
The reused native BUMP pose caption retains explicitly labelled mm/degree display;
that is a plotting boundary, not a change to stored values or table/curve units.

Empty numeric cells are unknown. Enter finite numbers separated by spaces,
commas or semicolons. MATLAB expressions, colon ranges, NaN and Inf are rejected;
no eval/str2num input execution. No range midpoint or missing CG/radius is inferred.
Roles, availability, provenance and confirmation remain separate native fields.
RULE/TARGET cannot supply physical data. Extra JSON is data only and carries
structured rule/derivation references when explicitly supplied. Existing origin,
notes, metadata and unedited records are preserved.
Extra JSON accepts exactly `ruleReference` and `derivationReference`, with these
case-sensitive canonical names. It is not an alternative editor for Value,
Bounds, Role/type, Availability, sourceKind/sourceNote, confirmation, origin,
ID, unit, scope or binding. Unknown keys and normalized/case variants of explicit
fields are rejected with the row, parameter ID and offending key before any
canonical project operation. Every row is preflighted, including unchanged rows.
Duplicate root keys and nonliteral/normalized aliases are rejected too, including
aliases that would collide with a permitted name after jsondecode normalization.
Quoted reference text remains ordinary data, not another key or executable code.
The cell must be a JSON object, not an array/scalar/null. `derivationReference`
is scalar text (empty text is allowed); `ruleReference` is `{}` or an object with
all seven nonempty text fields: organizer, version, ruleId, quantity, source,
status, applicability. Canonical factories still validate role/reference semantics.
To clear references, explicitly supply `{"ruleReference":{},"derivationReference":""}`.
Opaque native description/metadata and other unexposed fields remain preserved
from the existing record; they cannot be overwritten through Extra JSON.
Search-table edits retain native metadata, transforms, references and unchanged
target origins. Non-BUMP targets, non-hardpoint variables, ROLL plans or distinct
left/right plans are preserved in the project but explicitly rejected by this
BUMP-only editor rather than silently reinterpreted.
Scenario notes, concept dependencies and native symmetry links are retained too.

Edits are drafts until Apply on the relevant page. Geometry groups retain the
other groups' draft rows. Apply decisions before changing scope. Complete or
apply other-page drafts before actions that would replace or save the project;
the app must not silently save a partially edited table. There is no autosave.

## Workflow A — incomplete project

1. On Project, start/reuse a process worker (recommended), or explicitly choose
   synchronous execution. The first process-pool startup can briefly block.
2. Choose a canonical project ID and New empty project. Confirm replacement if
   current data are unsaved.
3. On Vehicle, enter only known or explicitly assumed quantities and provenance.
   Declare the mass inclusion convention and supported architectures as needed.
4. Apply vehicle. Unknown quantities remain absent; no hardpoints are invented.
5. Save as a native MAT; reopen only trusted local files.

## Workflow B — decisions, geometry and BUMP

1. Project → Illustrative inputs loads the existing `parametricSeedInputs`
   software fixture without generating geometry or running BUMP.
2. Geometry → FRONT / MIRROR_FL. Inspect the28 decisions grouped into Wheel /
   References, Upright, UCA, LCA and Tie Rod. Change/apply only explicit inputs.
3. Check input readiness, then Build and adopt geometry. Nominal invalidity is
   reported and not adopted. Nominal VALID is not sampled BUMP feasibility.
4. Inspect the actual registered hardpoints, wheel circle, axis, arms and upright;
   rotate, zoom, restore view and use data tips. No undefined rack/rocker is drawn.
5. Analysis → declare samples such as `-0.01 0 0.01` in metres, then Run BUMP.
   FRONT delegates one native BUMP per registered front corner.
6. Inspect five metrics, convergence, native diagnostics, reciprocal conditioning
   and the existing reliability policy. Failed samples remain NaN/gaps. State
   selection includes only actually converged samples, never interpolated poses.
7. Save/reopen. Replotting stored evidence never runs another forward solve.

### Historical evidence and current applicability

Analysis retains historical curves and poses. Both views show compatibility from
`fsd.project.resultCompatibility`, using the Controller's canonical report cache
when available. Revision numbers identify/order executions; they do not determine
obsolescence. `CURRENT_EXECUTION` and `REUSABLE_DEPENDENCIES` are applicable;
`STALE`/incompatible evidence is explicitly marked HISTORICAL ONLY / NOT current
geometry evidence. Original CONVERGED, reliability and rcond remain original
diagnostics, never proof of current applicability.

Warnings and curve legends identify the stored result; the pose caption repeats
its compatibility alongside the native sampled-pose caption. The warning areas
identify its actual scenario source, corner/frame, execution
project revision and current registered corner/frame/current project revision.
There is no fabricated separate geometry revision in the native model.
The pose view prefers applicable evidence, then the newest execution revision,
not the lexical order of result IDs. Older curves retain their own status even
after a new applicable BUMP appears. Warning text areas scroll when necessary.
Warnings occupy their own row above the plots, not the pose viewport. Mixed
historical/applicable curves are identified as mixed rather than all being called
current or all obsolete.

Applied decisions update the recipe; Build/adopt changes the registered geometry.
Compatibility follows the canonical dependencies at each stage, not unapplied
drafts. Relevant construction/adoption, project replacement and MAT load refresh
the views. Independent mass/description changes can remain REUSABLE_DEPENDENCIES.
Neither refresh nor warning presentation reruns a solver or rewrites a snapshot.

For FL/FR/RL/RR choose that scope and supply its explicit28 decisions. FRONT /
NONE requires separate FL and FR sets; FRONT / MIRROR_FL is an explicit reflection.
Geometry validation, side/sign rules and origin bindings are native v0.17.

## Workflow C — targets, search and comparison

1. Targets → add explicit BUMP target rows using CAMBER, TOE, BUMP_STEER, CASTER
   or KPI. Declare source alias/corner, point/curve/band/bound type, HARD/SOFT,
   domain, values/bounds/tolerance, normalization, weights and justification.
   New search configurations use the native composite-score option, requiring
   at least one explicitly scaled/weighted SOFT objective; no objective is
   invented for a HARD-only declaration. An existing native option is preserved.
2. Synthesis → declare authorized UCA/LCA chassis XYZ variables, absolute bounds,
   FREE/RANGE or FIXED role and explicit FIXED comparison tolerance. Optional
   nominal boxes/FIXED hardpoints are not CAD collision checks.
3. Set native search budget/options and BUMP plan; Apply search configuration.
   Native validators reject incompatible scopes, targets, bindings and options.
4. Check readiness, then Run native synthesis. Corner delegates v0.12; FRONT
   delegates the single coordinated v0.13 controller with two BUMP sources.
   Undeclared opposite-side variables stay fixed, not implicitly optimized.
5. Results retains scores, HARD status, eligibility, reasons, selection, original
   revision, history and stop reason. Inspect seed versus any stored candidate,
   its geometry and five BUMP curves. No new solve is performed on redraw.
   The seed is grey/dashed; the inspected candidate uses colored members.
6. Compatibility is refreshed on committed project changes by the worker; Check
   compatibility / STALE explicitly refreshes it as well. Adopt an eligible current/reusable
   candidate only; native registry validation rejects incompatible associations.
   Old result snapshots stay unchanged and become STALE as appropriate.

Adoption changes the registered geometry, not the original 28-decision seed
definition: no inverse fitting of that parametric family is invented. Building
the original definition again deliberately reconstructs/adopts its geometry.
Corner adoption changes only that corner; it does not mirror an optimizer result
onto the opposite side implicitly.

For a reproducible software-only demonstration, after building the illustrative
FRONT use **Load illustrative reference targets (NEW BUMP)** and confirm it.
This explicitly executes the same reference BUMP and declares the same targets,
bounds and scales as `conceptToSeedExample`. They are NOT recommended vehicle
targets. Then run the FL search: the audited known case is7 candidates /7 BUMP,
score0.101722096447→0. The app never substitutes precalculated results for this run.

RACK/steering synthesis, automatic optimal targets, new dynamic models, CAD/rules,
Adams, deployment and v0.19 are outside this interface milestone. Existing such
evidence in a native project is preserved, not deleted or relabeled as UI support.

## Asynchronous operation contract

The v0.19 [RF-03 reception contract](v0.19-rf03-operation-contract.md) additionally
binds canonical native content to the immutable owner operation, not only to
response IDs/policy. Its matrix covers all19 actions, APPEND/REPLACE/UNCHANGED,
reference sweep evidence and requested MAT content. Canonical receipt can still
block UI callbacks; asynchrony is not a guarantee of continuous responsiveness.

Parallel Computing Toolbox is used for coarse `parfeval` process tasks, not
parallel candidate evaluation. An existing local process pool may be reused; only a
pool created by this session is eligible to be closed by it. If another app/user
has queued or running work on that global pool, it is retained and relinquished
rather than aborting foreign work; MATLAB/user then manages its lifetime. A thread pool is rejected rather
than silently claiming every solver/MAT path is thread-safe. Missing PCT uses
only explicitly selected synchronous execution, with an honest blocking UI.

Each task receives a plain-data immutable project snapshot, operation ID and
UI epoch. Any presentation edit advances the epoch. A mismatched/stale return
cannot replace the current project or publish a MAT. Only one task can own the
session/save target. Actual task start/completion/errors are shown; there is no
fabricated percentage or per-candidate progress unsupported by the native API.
Completion has an ownership guard against callback/timer reentry while MATLAB
fetches outputs or renders the UI, so a response is consumed only once.

Save validates/writes a task-owned temporary MAT in the destination directory
through `saveEngineeringProject`; only a current successful response publishes
it. Overwrite requires explicit confirmation; a changed destination stamp aborts
publication. Cancellation/stale/error removes only that exact task-owned temp
after the worker finishes. This is a single-session guard, not a distributed file
lock or protection against an adversarial external writer between stamp and move.

Cancellation calls MATLAB's real Future.cancel and waits for the actual finished
state. Close is blocked while resources are active. Programmatic figure deletion
requests cancellation and keeps the polling owner until completion, then releases
only task-owned resources. No user MATLAB session or preexisting pool is stopped.

## Parallel performance decision

Accepted R2026b baseline: two process workers,63 native candidate equivalence
pairs, clocks excluded only; full native delegated search E7/BUMP7/score0 matched.
Median sequential/parfor seconds for N1/4/16:0.2187978/0.2989137,
0.4672333/0.6288040,1.7110892/1.7874835. Pool startup10.291839s.
No acceleration was demonstrated, so no parfor/default numerical parallelism is
introduced. Asynchrony is for UI availability, not a claimed speedup.
CPU/RAM, transfers, errors/gaps, DataQueue and backgroundPool probe evidence
remains under `output/r2026b-audit/parallel-probe.mat` and `parallel-final.log`.
The new production adapter deliberately uses process tasks, not an unverified
threaded generalization of the one backgroundPool fixture.
Remote ClusterPool sessions are not reused or altered: this local-only workflow
does not implicitly transmit a project or assume shared remote MAT paths.
See the official [ProcessPool contract](https://www.mathworks.com/help/parallel-computing/parallel.processpool.html).

## Validation and open decisions

See [v0.18 validation](v0.18-validation.md) for actual executed results and limits.
Physical assumptions, real dimensions, packaging bounds, motion domains, target
weights and engineering tolerances remain the engineer's decisions. The displayed
65-point ideal wheel ring is a rendering tessellation, not a tire model or an
engineering tolerance. Native quality is local/sampled, not continuous feasibility,
structural strength, regulatory approval or manufacturing readiness.
