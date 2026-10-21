# v0.19 — Packaging & Physical Feasibility

This document specifies the implemented mathematical/interpretation contract;
actual executions and remaining validation limits belong in v0.19-validation.md.
No manufacturing, CAD, regulatory or continuous-motion certification is implied.

## Initial physical inventory and adapters

| Native item | Actual evidence | Physical data still required |
|---|---|---|
| Wheel center/axis | Nominal hardpoint/unit axis; verified rigid upright pose | Tire/rim/brake solids and dimensions |
| Effective radius | Explicit construction decision / circular contact reference | Not a tire section, unloaded radius, rim cavity or offset |
| Upright, UBJ/LBJ | Five material points, proper rigid transform | Material envelope(s) |
| UCA/LCA | Declared member connectivity and moving ball joints | Explicit tube segments and radii; no triangle fill |
| Tie rod | Two endpoints; inner fixed in BUMP, translated in RACK | Radius and joints |
| Pushrod/pullrod | Optional ActuationGeometry/ActuationResult | Rod/joint material envelopes |
| Rocker | Optional common solved rotation and two attachments | Solid shape; axis line is NOT a bearing |
| Damper | Optional solved endpoints/length | Body/shaft/eyelet dimensions and local attachment semantics |
| BUMP | Native ordered samples, poses, failures and identity | Direct stored-state adapter; never a new solve |
| ROLL | Native corner results in chassis coordinates | Separate adapter/verification; not an invented world-frame vehicle pose |
| RACK | Native steering corner poses and actual inner joint | Separate adapter/verification; not combined roll/steer |
| Combined bump/roll/steer | No general native combined solver | NOT_EVALUATED, not inferred from independent sweeps |

The first adapter consumes nominal geometry and stored BUMP. Further adapters
must pass native source validators and retain their actual chassis frame and
joint positions. Unsupported movement/component attachments remain explicit.
Hardpoints without dimensions do not become physical volumes automatically.

## Boundaries and representation

`fsd.packaging` is a value-only downstream consumer of native model/geometry/
kinematic evidence. No app imports, forward solves or synthesis searches.
Project orchestration owns canonical revisions/compatibility and native MAT;
the UI only edits declarations and plots stored results. Historical scores,
eligibility, search order, models, tolerances and solvers are not changed.

SI metres/radians, +X rear/+Y right/+Z up and the original global origin remain.
Points are rows. A transform T maps component-local column coordinates to the
declared parent frame: p_parent = R*p_local + t. R is proper orthonormal,
det(R)=+1, T(4,:)=[0 0 0 1]. Validation delegates rotation checks to the existing
rigid-transform API/numericTolerances. Reflection is not a proper frame: reflect
positions and conjugate orientation S*R*S explicitly, never store det=-1 as R.
Vehicle-parallel corner frames may translate, not redefine lateral axes.
Nominal vehicle and fixed-chassis coordinates coincide for the BUMP adapter;
this does not assert that chassis and world frames coincide during body roll.

Volumes have stable ID/component ID/type, frame, shape, dimensions, nominal
local-to-parent pose, FIXED/UPRIGHT/SEGMENT binding, source, fidelity, source
revision and provenance. Empty dimensions are missing data, not zero material.
Known dimensions must be finite positive; capsule centreline length may be zero
(a sphere), explicitly distinguished from a positive radius. Input length units
are converted once at construction. No engineering dimension has a default.
Spheres/capsules/boxes represent declared simplified occupied material, not CAD.
Rim interior is free space and cannot be used as an occupied solid obstacle.
Users can declare several separate material primitives, including a segmented
rim representation, but must label approximation/fidelity and coverage honestly.
No solid cylinder is silently substituted for the interior of a wheel rim.

SEGMENT capsules follow exactly two declared native point IDs: circular section
does not require an unobservable axial twist. No arbitrary automatic connection
between all arm points. UPRIGHT volumes follow the stored proper rigid transform;
wheel spin is not resolved by it. Tire outer envelope may use an explicitly
declared conservative representation, but this is not a rim-interior check.

## Distances and numerical contract

Production kernel: base MATLAB analytic finite primitives. Navigation Toolbox is
an optional independent comparison/oracle, NOT a required production dependency.
For intersecting closed occupied sets, unsigned minimum distance is zero.
Penetration depth is not inferred from this distance. Separated witnesses belong
to their respective surfaces; unavailable intersection witnesses remain NaN.
No bounding-box lower bound is published as an exact distance.

Sphere/sphere and capsule/capsule: minimize distance between centre points or
closed centreline segments, then subtract radii; clamp unsigned separation at
zero. Segment p(s)=p0+s*u, q(t)=q0+t*v, 0<=s,t<=1. Candidates comprise the four
endpoint projections plus a feasible interior stationary point of squared
distance. Degenerate zero-length segments reduce to point projections; parallel
segments are covered by endpoint projections, with no division by zero.

Sphere/box uses a proper inverse transform and coordinate clamp to box half
extents. Segment/box minimizes the convex piecewise quadratic squared distance
from p(s) to the AABB in box coordinates. Split [0,1] at every face crossing;
within each interval the active coordinates are fixed, so inspect its endpoints
and its feasible quadratic stationary point. Capsule/box subtracts its radius.
Box/box intersection uses the separating-axis theorem (face normals and nonzero
edge cross products). For disjoint boxes, minimum distance occurs at vertex/face
or edge/edge features: inspect all vertices against the other box and all edge
pairs. No iterative nonlinear suspension solver or optimizer is involved.

Broad phase computes conservative AABB lower separation bounds and may prune
intersection-only candidates. Exact reported minimum distances still require
narrow phase; per-check broad-phase flags distinguish discarded collision candidates
from completed exact distance checks. No broad-phase-only CLEAR at an unknown
distance is used to populate a precise minimum.

Numerical comparison budgets reuse numericTolerances (AbsTol_m/RelTol), scaled
by the supplied coordinates/dimensions; these are NOT required physical margins.
The user supplies every required clearance. Near-boundary floating-point
ambiguity must not create a false CLEAR. Analytic tangency cases and slightly
above/below-margin cases require independent tests. Unsupported shape pairs
return NOT_EVALUATED with NaN distance, never an invented zero/large clearance.
The kernel comparison budget is not a bound on native pose error, dimensional
measurement uncertainty, manufacturing tolerance or model fidelity. Those are
not propagated into a guaranteed physical clearance in this release; choosing
appropriate engineering allowances remains an explicit OPEN DECISION.

## Coverage, exceptions and interpretation

Required pairs are explicit volume IDs, not all pairs within a corner. Exceptions
must identify the exact pair/components, rationale and provenance. A joint-contact
exception must not exclude a whole tube against rim/chassis. Split local joint
and tube envelopes when only joint contact is intended. No global corner-level
exemption exists. Exempt checks remain visible and counted separately.

Classification distinguishes CLEAR_SAMPLED, COLLISION_DETECTED, LOW_CLEARANCE,
INCOMPLETE and NOT_EVALUATED. A demonstrated collision has priority over missing
checks but coverage is reported separately, so COLLISION_DETECTED does not imply
complete coverage. CLEAR_SAMPLED requires every nonexempt required check at every
required sample, all source states valid and sufficient margins. Empty/all-exempt
evaluations are NOT_EVALUATED. A failed/missing pose or dimension is INCOMPLETE;
an unsupported check is NOT_EVALUATED at row level and prevents aggregate CLEAR.
Convergence is necessary, not a certification of physical data or branch quality.

Nominal and sampled domains remain distinct. Preserve requested order, samples,
failed states and source identities. No interpolation of failed states or poses,
no claim about collisions between samples. Refinement requires an explicit new
native BUMP run, outside packaging; it never silently calls the solver.
FIXED/inside/outside hardpoint regions verify supplied points, not generate them.
Their user-supplied clearances/comparison tolerances are recorded separately from
numerical budgets. Candidate evaluation remains an extra comparison column, never
a modification of historical HARD/SOFT or score.

## External API checks and limits

Navigation Toolbox26.2/R2026b is installed and license test returns1 locally.
Official collisionCapsule uses metres, local Z centreline, midpoint origin, length
excluding endcaps; zero centreline length is allowed. checkCollision supplies
separation/witnesses for convex objects; by default intersections yield NaN
distance/witnesses. Optional UsePenetration is a separate signed-depth API.
Its documented sub-1e-5m reliability limit prevents using it as a tangency oracle.
collisionMesh is convex, not arbitrary concave CAD. Cylinder/mesh are inspected
APIs, not a promise of production support or exact rim representation.

- [MathWorks collisionCapsule](https://www.mathworks.com/help/nav/ref/collisioncapsule.html)
- [MathWorks checkCollision](https://www.mathworks.com/help/nav/ref/collisionbox.checkcollision.html)
- [MathWorks collisionMesh](https://www.mathworks.com/help/nav/ref/collisionmesh.html)
- [MathWorks collisionSphere](https://www.mathworks.com/help/nav/ref/collisionsphere.html)
- [MathWorks collisionCylinder](https://www.mathworks.com/help/nav/ref/collisioncylinder.html)

OPEN DECISIONS: actual physical dimensions/material coverage, approximations,
joint-contact regions, engineering margins, motion domains and refinement policy
belong to the engineer. No Formula Student universal clearance is invented.

## Public value contracts / usage

`createVolume(d,'m'|'mm')` requires exactly:
`id,componentId,componentType,role,frame,shape,dimensions,transform,binding,source,
fidelity,sourceRevision,provenance`. IDs are stable uppercase identifiers.
Frame uses the existing `id,originDescription,axisConvention` contract, not a
bare axis label. No automatic frame registration or guessed frame transform.
Optional third argument `DIAMETER` converts only the circular primitive's first
dimension using r=D/2, at the input boundary. Stored dimensions always contain
radius; `RADIUS` is the default representation, not a physical default value.
UI dimensions accept `D: 0.008` (diameter8mm entered in metres); ordinary entries
are radii. Capsule centreline length and box sizes are never divided by two.

| Shape | Explicit dimensions before resolution | Supported occupied pair families |
|---|---|---|
| SPHERE | radius | sphere, capsule, AABB/OBB |
| CAPSULE, FIXED/UPRIGHT | radius, centreline length excluding caps | sphere, capsule, AABB/OBB |
| CAPSULE, SEGMENT | radius only; two native endpoints provide centreline | same after resolution |
| AABB / OBB | three full edge lengths | sphere, capsule, AABB/OBB |
| CYLINDER | radius, length, preserved declaration only | NOT_EVALUATED; not rendered as claimed material |

No mesh/CAD/cylinder narrow-phase support is claimed. An explicit collection of
primitive volumes is evaluated pair-by-pair; overlap among a component's own
primitives does not automatically add required pairs. The engineer controls
material completeness and fidelity. Empty dimensions remain INCOMPLETE.

Binding is exactly `mode,cornerId,pointIds`: FIXED has blank corner/empty IDs;
UPRIGHT has explicit corner/empty IDs; SEGMENT has explicit corner/two distinct
native IDs, identity nominal transform and capsule radius only. UPRIGHT T is a
nominal component-local-to-parent transform, moved by the actual native rigid
pose about its stored reference point; it is not an arbitrary wheel-spin frame.

`createDefinition` takes `id,volumes,pairs,regions`, the last three cell vectors.
Each pair is `id,first,second,requiredClearance_m,exception`. Exception is [] or
`id,firstComponent,secondComponent,reason,source`. It is exact-pair only, requires
a JOINT participant and excludes tire/rim/obstacle participants. Declare local
joint geometry separately; never re-label a full tube as a joint to exempt it.
Each region is `id,cornerId,pointId,mode,volumeId,target_m,tolerance_m,clearance_m,
source,provenance`. FIXED supplies target/tolerance and no volume/clearance;
INSIDE/OUTSIDE supply fixed volume/clearance and no target/tolerance. Containment
is of the point, not the entire upright/arm. Boundary equality for a point-region
is inclusive; numerical collision-margin ambiguity is conservatively incomplete.

`evaluate(definition,geometry,plan,source)` takes exactly plan fields `mode,
requested_m`. NOMINAL requires both empty grid and source; BUMP requires an
explicit finite grid identical to native `BumpSweepResult.requestedWheelTravel_m`.
Missing BUMP source is represented as missing required samples, not nominal.
No interpolation, hidden solve, reordering or requested-versus-resolved substitution.
`validateResult` reconstructs the algebraic checks, not the kinematics.
`plotResult(result,ax,sampleIndex,checkIndex)` draws stored poses/solids and
available witnesses. Invalid source poses do not display mobile geometry as valid.

Project entry: `createPackagingScenario(id,cornerId,packagingId,plan,parent,
selection,candidateIndex)`. Parent is [] for nominal REGISTRY or an original
native EngineeringResult for BUMP/CORNER_SYNTHESIS/AXLE_SYNTHESIS. Selection
REGISTRY uses actual registered geometry; SEED/CANDIDATE select the actual stored
record's geometry and BUMP source. SEED additionally verifies native seed identity.
The selected/adopted registry geometry may be assessed nominally or with its own
compatible native BUMP. Stale parent blocks preparation; source/geometry/grid
mismatch cannot yield CLEAR. No new synthesis score or candidate eligibility.
The factory verifies the original EngineeringResult and stores a bounded
PackagingSourceReference, not another execution. It retains original ID/revision/
software/sourceIdentity and the exact native payload/assessment, plus a dependency
snapshot omitting Packaging scenarios/resources and the empty ledger. Every
native scenario/resource/concept is retained, including seed origin gates; the
entire reconstructed preparation must equal the original. That invariant, not a
guess about dependencies, authorizes projection. The UI retains the original
complete result unmodified in its ledger; standalone API callers retain their
original record explicitly if they need the complete execution configuration.
The projection is not a replacement for that original historical record.
`validatePackagingSource` reconstructs native
evidence from the dependency snapshot; canonical `resultCompatibility` handles
the explicit new type using the same consumed-context logic. A projection is
never CURRENT_EXECUTION. Historical full-parent v0.19 development evidence can
still be read, but new scenarios do not recursively copy parent configurations.
Canonical historical synthesis validators replay the deterministic controller
against stored records to check trace integrity; this is not a new physical
search. Packaging must invoke no forward solve, physical candidate evaluation
or `run*InverseSearch`. That distinction is checked by profiler caller evidence.

## Native MAT and process transport

Packaging projects use one native MAT file with a versioned physical header
`FsdEngineeringProjectStorage`0.19 / `FSD_VALUE_GRAPH_V1`. The configuration and each
original ledger record occupy separate variables. The logical project and all
original records, identities, numeric classes/values, ordering and provenance
are restored exactly; no history is replaced by a summary. `encodeStorageGraph`
and `decodeStorageGraph` use backward-only node references and a text dictionary,
preserving classes/shapes, missing, Unicode, complex/sparse flags, signed zero
and numeric values. Only exactly equal typed subtrees share encoded storage;
no identity/revision-only or hash-only interning. This is an I/O representation,
not a new logical model, database or external technology. The previous development
FSD_TEXT_V1 format/converters remain supported by the reader.

The storage writer preflights one encoded record at a time. An operation-local
32MiB I/O buffer retains already encoded graphs only while they fit that budget,
avoiding a second conversion for them. Larger/unbuffered records use the prior
one-at-a-time re-encoding fallback. There is no history/candidate/data cap,
global cache or unbounded full-ledger transport allocation. It normally uses
MAT v7; an individual
estimated variable at least2^31bytes selects v7.3. WHOS is not a proof of on-disk
size; missing/skipped variables fail the final inventory check. Multi-GB single
records have not been stress-tested. The official per-variable/file limitations
are described by [MathWorks MAT file versions](https://www.mathworks.com/help/matlab/import_export/mat-file-versions.html).

The canonical loader also accepts old `FsdEngineeringProjectFile`0.16 files.
Classic projects without Packaging AND without results retain the old writer.
Histories without Packaging also use the bounded0.19 writer: native synthesis
snapshots otherwise trigger the same legacy serializer memory peak. Legacy
0.18 MAT input remains readable; newly written history files require0.19.
New history/Packaging files
must be opened through `loadEngineeringProject`, not raw `envelope.project`
assumptions. No sidecar directory, database, opaque object cache or external
technology is introduced; schema0.16 logical projects remain value structs.

The UI transport uses the same reversible conversion. ENCODING/DECODING operate
only on plain values cooperatively, yielding UI callbacks at256-visit/node
scheduling quanta; engineering and MAT I/O remain on the owned/reused ProcessPool.
No solver or search is certified for threads by this change. Completion/reentry,
operation/epoch, cancellation and single-writer guards cover all phases. The
production path no longer starts backgroundPool merely for conversion. No
global thread setting or unrelated shared pool is changed/deleted. Explicit
codec thread-support tests are independent of that production policy. See the
official [backgroundPool worker policy](https://www.mathworks.com/help/matlab/ref/parallel.backgroundpool.html)
and the actual runtime measurements in v0.19-audit-corrections.md.
The request contains only the ledger records needed by that operation; unrelated
history remains at its immutable owner and is canonically merged on return.
SAVE/VALIDATE/COMPATIBILITY do not echo their full input project; LOAD does not
send the project being replaced. All original full execution configurations and
native evidence remain intact. Merger inputs are each validated once, then their
exact immutable ledger values are composed with canonical association/ID checks.
No global cache, public skip-validation flag or change to geometry/search.
`resultCompatibilities` validates one project and classifies its ledger with the
same private implementation as singular `resultCompatibility`.

This boundary addresses a measured24GB-private-memory SAVE failure; it is not
a universal latency or arbitrary-history-size guarantee. Final evidence is in
v0.19-validation.md.

```matlab
setupProject; addpath('examples');
e = packagingFeasibilityExample(false); % explicitly requested synthetic inputs
r = e.moving.nativePayload;
r.status
r.coverage
r.minimumObservedDistance_m % only the declared pairs at supplied samples
```

This integrated release adapter is corner NOMINAL/BUMP only. RACK/ROLL native
evidence exists, and the low-level resolver can consume a validated steering
corner including its true moving inner joint (with a real native RACK-corner
test), but aggregate project/grid/frame adapters and sweep tests are not provided
here. Their integrated motion coverage
is NOT_EVALUATED, not an inferred combination. Actuation endpoints alone are not
a solved material envelope: dynamic rocker/damper/rod bindings are not supported.
Fixed declared obstacles may approximate those parts only in the declared fixed
frame, never as a claim of their actual motion. Cross-corner moving assembly,
world-frame body motion, arbitrary component frames, exact concave rim interior,
automatic adaptive refinement and continuous collision detection are not covered.
