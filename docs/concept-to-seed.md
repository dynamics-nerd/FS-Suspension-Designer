# v0.17 — Concept-to-Seed & Parametric Suspension Geometry

## Scope and boundaries

Independent rigid double wishbone, one FL/FR/RL/RR or a FRONT pair. A FRONT
pair is explicitly MIRROR_FL or independent; no implicit symmetry. Construction
is deterministic geometry, not synthesis, target generation or a new solver.
The original ten-point geometry/factories/identities remain unchanged.
Vehicle mass, CG, gravity and unloaded tire radius are NOT construction inputs.
No CAD clearance, strength, tire performance, rules or manufacturing certification.

`fsd.construction` consumes native DesignParameter records and geometry/model
APIs and the historical nominal builder/constraint evaluator through pure
adapters. It does not depend on project or UI and never invokes search or
kinematic solves. `fsd.project`
selects physical concept inputs using the v0.16 gate, orchestrates construction,
and optionally delegates an explicit BUMP to the historical public APIs.
Native physical modules do not depend on construction or project.

## Reference family and coordinate construction

The family is `INDEPENDENT_DOUBLE_WISHBONE`. It must be selected explicitly.
SI m/rad and +X rear/+Y right/+Z up are unchanged. Contact datum C is exactly
`[0,s*frontTrack/2,0]` or `[wheelbase,s*rearTrack/2,0]`, s=-1 left/+1 right.
Wheelbase and the applicable track are required physical concept quantities,
even for a front corner, to maintain a coherent vehicle reference and rear
steering reference. Other track is not required and is UNKNOWN when absent.

An explicit `WHEEL_EFFECTIVE_RADIUS` defines the nominal ideal circular-wheel
reference used by the existing contact model. It is NOT automatically an unloaded
or measured loaded tire radius. The engineer must justify this geometric
approximation. With a unit outward wheel axis a, use native geometricWheelContact
at origin to find the lowest vector d; then WC=C-d. Thus the datum is in the
wheel plane and on nominal ground, including nonzero camber/toe.

Toe t is positive toe-in; camber c is negative for top-in, per historical APIs.
Both must satisfy abs(angle)<pi/2 (representation domain, not an FS limit).
Use b=s*t and alpha=-s*atan(tan(c)*cos(t)); R0=Rz(b)*Rx(alpha).
This gives native toe t and camber c without redefining either projection.
Axis a=R0*[0;s;0]. Upright clocking k is explicit: apply native rotation about
a by -s*k, R=Ra(-s*k)*R0. Clocking zero means this declared reference orientation;
it is never an inferred physical setup. Clocking changes attachments, not wheel axis.

Each upright offset is `[x,s*outboard,z]` relative to WC in the nominal
vehicle-parallel reference. Its global point is native rigid transform R+WC.
R is a proper rotation on either side. Multiplying an offset's lateral component
by s is a side-normalized construction convention, NOT a physical reflected
frame for moments/cross products. Mirroring a corner uses the historical
reflection API; mirrored proper orientation is S*R*S, S=diag([1,-1,1]).

## Required construction decisions

Every scalar is a native DesignParameter created through the catalog wrapper.
No scalar has a physical default, including zero gradients or angles.

| IDs | Quantity / reference | Requirement |
|---|---|---|
| WHEEL_EFFECTIVE_RADIUS | Positive length, ideal nominal wheel circle | REQUIRED / ASSUMED_EXPLICIT if hypothetical |
| NOMINAL_TOE, NOMINAL_CAMBER | Native signed angles | REQUIRED |
| UPRIGHT_CLOCKING | Side-normalized clocking defined above | REQUIRED |
| UBJ_X, UBJ_OUTBOARD, UBJ_Z | Upright reference offsets from WC | REQUIRED |
| LBJ_X, LBJ_OUTBOARD, LBJ_Z | Same | REQUIRED |
| TIE_OUT_X, TIE_OUT_OUTBOARD, TIE_OUT_Z | Rigid upright pickup offsets | REQUIRED |
| UCA_CENTER_X, LCA_CENTER_X | Pivot-line midpoint X offset from contact C | REQUIRED |
| UCA_LATERAL, LCA_LATERAL | Positive outward midpoint distance from centerline | REQUIRED |
| UCA_HEIGHT, LCA_HEIGHT | Midpoint Z above nominal ground datum | REQUIRED |
| UCA_SPAN, LCA_SPAN | Positive aft-minus-forward longitudinal separation | REQUIRED |
| UCA_LATERAL_DELTA, LCA_LATERAL_DELTA | Aft-minus-forward outward distance | REQUIRED |
| UCA_HEIGHT_DELTA, LCA_HEIGHT_DELTA | Aft-minus-forward height | REQUIRED |
| TIE_IN_X | Inboard X offset from C | REQUIRED |
| TIE_IN_LATERAL, TIE_IN_HEIGHT | Outward distance from centerline / global Z | REQUIRED |

For each arm, FWD = [Cx+centerX-span/2, s*(lateral-deltaY/2),
height-deltaZ/2], AFT uses all plus signs. Both inboards must remain on their
declared side and inboard of that arm's ball joint. This is a deliberately
restricted family, not a claim that all unusual native geometries are invalid.
Native validators remain the authority for links/upright and associated models.

Reconstructed contact, WC, axis, frame, hardpoints and link lengths are DERIVABLE.
Nominal native hardpoint FIXED/boxes are OPTIONAL; no solids clearance is implied.
Steering association is OPTIONAL and explicit, using the existing tie endpoints
and physical wheelbase through createSteeringSystem; rack construction is not
requested silently. Actuation generation, loaded tire deformation, hub surfaces,
FREE mechanical rates, automatic target selection and arbitrary architectures
are NOT_SUPPORTED. Upright offsets are minimal extra decisions, not renamed
global XYZ hardpoints: wheel, orientation and pivot-line parameters affect
multiple reconstructed coordinates coherently.

## Roles, intervals and dependencies

KNOWN/FIXED physical data and explicitly documented ASSUMED data are usable.
RULE/TARGET never supply physical dimensions, independent of provenance or
confirmation. Native v0.16 pending confirmation remains blocked. RANGE/FREE
with bounds but without an explicit scalar remains incomplete; no midpoint.
Explicit scalar selection preserves bounds/provenance. DERIVED requires the
native derivation reference; external declarations are not authenticated or
executed as code. Structured source definitions remain in result snapshots.
Native identity excludes metadata; descriptive construction text does not change
physical dependencies. Original values and source notes are still retained.

Coordinate derivations record input IDs and references, not just a DERIVED flag.
Changing radius/orientation transforms WC and all upright attachments together;
changing an arm-line decision transforms its two pivots together. Rebuilding a
definition always uses original inputs, never edits the previous geometry in place.

## Three independent stages

1. Input readiness: READY / MISSING_DATA / INVALID_INPUT / UNSUPPORTED, with IDs.
2. Nominal validity: VALID / INVALID / NOT_BUILT. Native factories, family
   restrictions, conceptual consistency and nominal HARD constraints are checked.
3. Sampled BUMP: NOT_CHECKED until explicit execution; full native source, native
   diagnostics, conditioning/branch guard, convergence and gaps remain available.

The input-stage checker does not construct a seed. Project configuration
validation may algebraically reconstruct already registered origin bindings;
that verifies stored nominal data, does not publish/adopt new geometry and never
executes BUMP/search. It is not a promise of zero-cost project validation.

Numerical comparisons reuse numericTolerances (AbsTol1e-9m/RelTol1e-9) with
AbsTol+RelTol*max(1,abs(expected),abs(actual)). This is double comparison, NOT
design/manufacturing tolerance. HARDPOINT_FIXED uses its own explicit tolerance;
Angles and dimensionless frame checks use RelTol*(1+max(1,abs(actual),abs(expected)))
as a numerical comparison in rad/1, not a dimensional length tolerance.
boxes retain the original exact bounds policy. Sampled constraints are not
continuous certification. No plot interpolation fills physical gaps.

Concept consistency uses MATCH/MISMATCH/UNKNOWN/NOT_APPLICABLE. Native validity
alone cannot certify track, wheelbase or contact placement against a concept.
No mismatch is corrected by moving geometry silently. Only present axle geometry
can demonstrate its track; an absent axle remains UNKNOWN.

## Project, evidence and persistence

Construction scenarios are deterministic actions, not synthesis. They retain
definition, original concept/revision, constraints, scope and reference inputs.
Construction is explicit; BUMP is a separate explicit action. Seeds are adopted
explicitly into the native resource registry, retaining origin bindings and the
historical result ledger. Existing incompatible steering/actuation/mechanics
must be revised explicitly, not deleted or fabricated by registration.

Bindings prevent nominally valid but obsolete generated resources from being
used as current seeds. Relevant concept/decision changes invalidate dependent
actions; mass/descriptive changes do not invalidate a purely kinematic seed.
Old snapshots remain valid historical records. Native synthesis consumes the
generated geometry directly; later optimized candidates have their own identities
and do not masquerade as unchanged parametric seeds.

MAT uses the existing project envelope and revalidates algebraically. New
construction records are schema0.17.0; existing physical schemas and historical
project records are preserved. Version eligibility is explicit; no automatic
migration or cryptographic authenticity is claimed.
The v0.17 reader accepts valid historical project records; older software is
not promised to understand new engines/origin bindings in a v0.17 project.
Full-ledger validation preserves the historical synthesis validator's deterministic
controller replay over stored records. That replay performs no new physical
evaluation; it is distinct from readiness, which invokes neither controller nor
forward solver, and from explicit execution of a new search.

## Public API and reproducible flow

Public additions (also indexed in src/+fsd/Contents.m):

- fsd.construction: seedParameterCatalog, createSeedParameter,
  createParametricSeedDefinition, validateParametricSeedDefinition,
  seedReferenceIds, parametricSeedReadiness, buildParametricSeed,
  validateParametricSeedResult, checkConceptGeometryConsistency.
- fsd.project: checkConceptGeometryConsistency, checkParametricSeedBump,
  validateParametricSeedBump, createSeedSteering, registerParametricSeed.
- fsd.synthesis: validateNominalSeed exposes the existing nominal-builder
  checks without executing BUMP; bumpSweepQuality exposes the existing native
  quality policy for an explicitly supplied geometry/sweep pair. Neither
  adapter introduces another numerical/physical criterion.

```matlab
setupProject; addpath("examples", "tests");
[concept,definition] = parametricSeedInputs("FRONT"); % illustrative inputs only
scenario = fsd.project.createEngineeringScenario(struct( ...
    'id',"BUILD",'engine',"PARAMETRIC_SEED", ...
    'scope',fsd.model.designScope('AXLE','FRONT'), ...
    'inputs',struct('definition',definition)));
project = fsd.project.createEngineeringProject(struct( ...
    'concept',concept,'scenarios',{{scenario}}));
readiness = fsd.project.designReadiness(project,"BUILD");
result = fsd.project.runEngineeringScenario(project,"BUILD","NOMINAL");
seed = result.nativePayload.seed;
check = fsd.project.checkParametricSeedBump(seed,struct('travel_m',[-.01;0;.01]));
project = fsd.project.registerParametricSeed(project,result);
```

`createSeedParameter(id,cornerId,definition,inputUnit)` fixes quantity/scope/binding
from seedParameterCatalog and uses the native DesignParameter factory. Definition
fields: id, description, family, cornerId, symmetry, parameters, rightParameters,
constraints. FRONT+MIRROR_FL consumes FL parameters; FRONT+NONE requires both sets.
All 28 scalar decisions are required, even when an explicitly chosen value is zero.
`seedReferenceIds` declares WHEELBASE and applicable track; standalone construction
uses native DesignParameter references. `fsd.project` additionally respects native
confirmation/state. `buildParametricSeed` returns an incomplete/invalid result with
no adopted geometry when appropriate; structural schema errors throw stable IDs.
`validateParametricSeedResult` reconstructs original coordinates and provenance.
`checkConceptGeometryConsistency` is available both for native reference parameters
and for VehicleConcept (project physical gate). An optional third argument
definition also compares native nominal toe/camber
and effective radius; absent declarations remain UNKNOWN, not assumed zero.
Frames include the wheel plane as its center and outward unit normal, not a
surface/tire model. `checkParametricSeedBump` executes; `validateParametricSeedBump`
only verifies stored native evidence.

PARAMETRIC_SEED consumes inputs.definition with empty plan/options/specification.
PARAMETRIC_BUMP consumes the same inputs and plan.travel_m/solverOptions; no search
controls or hidden solves. Both retain original EngineeringResult snapshots.
Readiness without registered scenarios preserves the twelve historical capability
prototypes; construction is inspected through an explicit parametric scenario,
not an invented default geometry definition.
`createSeedSteering(seed)` explicitly constructs a FRONT steering resource from
declared tie endpoints and wheelbase. `registerParametricSeed(project,result,steering)`
optionally associates it; omitting steering never makes RACK ready automatically.
Registration rejects obsolete results and incompatible resources; the caller must
revise ACT/MECH/RACK explicitly. When adopting a later optimized geometry, remove
its former seed binding explicitly as part of the resource revision, preserving
the original construction result in the ledger.

## OPEN DECISIONS (engineering inputs)

Real vehicle dimensions, effective wheel reference approximation, upright/hub
geometry, actual anclajes, packaging regions, motion domains, tolerances and
targets require engineering input. General curved/nonrectangular mounting regions,
automatic steering-arm/rack generation, actuation recipes, CAD/compliance and
external validation remain future specifications. No typical FS dimensions are
defaults. Illustrative fixtures demonstrate software, not a recommended car.
