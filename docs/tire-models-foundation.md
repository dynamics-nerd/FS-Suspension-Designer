# Tire Models Foundation — v0.22 development contract

## Status and dependency policy

Developer implementation and focused validation complete; independent audit pending. SI values and
plain structs; no mandatory add-on. Native family DUGOFF_REDUCED_1 and MathWorks
Dugoff are distinct model variants. Extended Tire Features26.2.3 has been probed
via public new/compute/import/export/struct APIs outside the repository. Native
model execution never calls it. No MathWorks implementation is redistributed.

## Exact native equations

Contact frame x forward, y left, z upward normal; forces are ground on wheel.
Global frame remains X rear/Y right/Z up. For forward motion,
alpha=atan2(Vy,Vx), kappa=(Re*omega-Vx)/Vx. Re is not inferred from R0 or loaded
radius. Given explicit slips, no speed or Re is required. Gamma positive means
wheel top leaning toward contact +y. Nominal gamma=-sideSign*geometricCamber;
non-nominal conversion projects actual wheel plane and heading on road normal.
contactFrame returns a proper rotation, never a left/right reflection frame.

dx=Ck*kappa/(1+kappa); dy=(-Ca*tan(alpha)+Cg*gamma)/(1+kappa).
The gamma term is enabled only by the explicit LINEAR_CONSTANT extension; at
nonzero gamma an UNSPECIFIED effect is missing data, not zero. r=hypot(dx,dy),
lambda=L/(2*r), F=d when r<=L/2, otherwise
F=(d/r)*L*(1-L/(4*r)). This is algebraically d*lambda*(2-lambda), arranged to
avoid multiplication of a huge demand by a tiny factor. At r=0 F=0 exactly.
The transition is continuous, with initial slopes dFx/dk=Ck, dFy/da=-Ca,
dFy/dgamma=Cg at zero slips/reference conditions. F approaches capacity L
asymptotically, not a calibrated post-peak curve. kappa>-1 and |alpha|<pi/2;
there is no hidden epsilon at wheel lock, no reverse/low-speed dynamics model.

Capacity: CONSTANT_MU gives L=mu0*Fz. REFERENCE_ONLY is evaluable only at Fz0
(or zero contact). POWER gives L=mu0*Fz0*(Fz/Fz0)^n. Stiffness has independent
REFERENCE_ONLY/CONSTANT/POWER laws C=C0*(Fz/Fz0)^p. No exponents are inferred.
Camber QUADRATIC capacity multiplies L by 1-qGamma*gamma^2, strictly positive
in admitted states. NEGLECTED must be explicitly selected. Thrust shifts demand
before saturation; it does not imply capacity variation or an optimum camber.
Extensions are reduced assumptions, not universal properties of Dugoff tires.

## Resource and API

create(definition), validate, capabilities, readiness(tire,states,request),
evaluate(tire,states,request), verticalModel(tire,corner), contactFrame.
Definition contains id/revision/name/level, geometry, vertical, force,
parameter provenance, declared evidence and note. Unknown scalars are [].
Each available scalar has sourceKind KNOWN/ASSUMED/DERIVED and sourceNote.
GENERIC/CUSTOM share one evaluator; level never certifies fidelity.
CALIBRATED/VALIDATED are user declarations requiring a reference, not automated
experimental certification. Empty uncertainty is not a zero error estimate.

States: Fz_N,alpha_rad,kappa,gamma_rad: scalar/vector; matching lengths or
explicit scalar expansion to N-by-1. No Cartesian expansion. Request channels
Fx/Fy/Mz and MARK/REJECT domain policy. Output arrays retain order and per-channel
status; unsupported/unrequested/missing/invalid/out-of-domain values are NaN.
NO_CONTACT is a physical zero for configured supported channels, not a new
capability of Geometry Only. Mz unsupported. MARK retains unavailable regions;
REJECT requires every requested channel/sample. Native domain bounds are explicit.
Readiness requests only the stiffnesses consumed by pure or combined states.
Pressure, thermal, rolling resistance and relaxation are not modeled.

## Project and vertical projection

Optional resources.tires holds immutable (id,revision) resources. Optional
tireAssignments holds cornerId,tireId,tireRevision. registerTire appends new
revisions and assignTires selects them. No fields injected into old projects.
TIRE_CHARACTERIZATION pins an exact revision, states, order, channels and policy.
Historical ledger/worker/semantic owner binding and native MAT are reused.

GLOBAL_STATIC keeps its historical inputs.tires route. New exclusive
inputs.tireSource=LIBRARY_ASSIGNMENTS resolves only R0/kt and their provenance
through the existing VerticalTireModel factory. Context includes tireId and
vertical projection, not full tire revision/force identity. Advancing the same
tire's force-only revision and assignment preserves vertical dependencies;
changing vertical data/source or resource association invalidates them.
Geometry radius is the single library unloaded-radius source; no rolling radius
is fabricated. Existing global physical equations and legacy payloads unchanged.

## Audit corrections V22-F-01/02/03 — 24 October 2026

The initial independent audit returned CHANGES REQUIRED with these three MEDIUM
findings. The corrections below are subsequent developer work, pending independent
confirmation; they do not rewrite the original audit or its validation results.

### Request presentation and incomplete plans (F-01)

normalizeRequest(request) is the single public normalizer used by evaluationInput
and TiresView: missing channels means [Fx;Fy], missing domainPolicy means MARK.
It requires no synthetic physical states and preserves the admitted channel order.
The view adds the exact requested channel sequence to its selector when needed,
including Fy+Fx and combinations containing Mz. Mz remains unsupported for execution.
Missing state fields are displayed blank; designReadiness remains authoritative.
LOAD/refresh changes no declarations. Only an explicit Apply creates a revised
scenario from the edited fields. Complete ready plans may run before Apply, retaining
the originally declared empty request or channel sequence in the execution snapshot.

### Physical reuse versus execution identity (F-02)

Complete prepared.context, scenarioAtExecution, tire identity/revision and result
identity remain unchanged. Exact reconstruction, worker RF-01/02/03 and MAT still
use this complete snapshot. compatibilityCore separately derives an ephemeral
TIRE_CONSUMPTION_1 projection through evaluationDependencies(tire,states,request).
No new prepared/result fields or MAT schema migration are needed. This preserves
authentic pre-correction v0.22 result reconstruction and provenance.

For the current native family, the projection includes normalized ordered states
and request, tire ID, family, all declared domains, and the following consumption
rules (conservative over every prescribed sample):

| Physical declaration | Included when |
|---|---|
| mu0 and capacityLoad | A supported Fx/Fy evaluation is requested |
| n | capacityLoad is POWER |
| Calpha and lateralLoad | Fy is requested, or any alpha is nonzero |
| pAlpha | Lateral declaration is consumed and lateralLoad is POWER |
| Ckappa and longitudinalLoad | Fx is requested, or any kappa is nonzero |
| pKappa | Longitudinal declaration is consumed and longitudinalLoad is POWER |
| Fz0 | Any consumed load law is REFERENCE_ONLY or POWER |
| camberThrust/camberCapacity | Any gamma is nonzero |
| Cgamma / qGamma | The corresponding consumed camber law is LINEAR_CONSTANT / QUADRATIC |
| Parameter provenance | Its parameter is included above |

Declared evidence quality/reference and the response's conservative model-wide
assumption flag also participate. Geometry and vertical properties are not force
inputs; unrelated library resources and unconsumed coefficients are excluded.
All domain bounds are retained because the evaluator checks them for each sample.
Conservative inclusion is intentional even where parameters happen to produce the
same values (for example a load exponent at its reference load or an unsaturated
capacity change). Reuse is never decided by equality of computed force arrays.
Unknown/future families or unsupported channel requests fall back to complete
identity projection; no derivative requests are supported by the current API.

The reuse scenario context excludes only the revision binding and raw plan; the
normalized effective states/request replace that plan. Channel/sample order and
domain policy remain relevant. Exact worker acceptance never uses this looser
reuse projection: an otherwise reusable response from another revision is rejected.
Reused evidence retains its original project/revision and is not a new execution.

### Canonical numeric boundary (F-03)

create accepts real built-in double/single and integer declarations. Integer
values must round-trip exactly through double and lie within +/-flintmax; larger
integers are rejected conservatively, including isolated exactly representable
integer values beyond this bound. Single values are widened without changing
their stored value. All available values must be finite and satisfy the existing
scalar/pair and physical-domain checks. Logical/text/complex/unsupported objects,
nonfinite values and incompatible shapes are rejected with InvalidDefinition.

The factory normalizes revision, geometry, vertical, force parameters and domain
pairs to full double; empty numeric fields become []. Identities are constructed
after normalization. validate requires this canonical double representation in
both definition and identities, so hand-assembled noncanonical resources are
rejected at the boundary. Call create explicitly to canonicalize a declaration;
there is no silent MAT migration of malformed resources. Readiness/evaluate then
consume the canonical resource without scattered arithmetic casts. Numeric
normalization changes no Dugoff equation, sign, load/camber law or tolerance.

Focused evidence: [v0.22 audit corrections](v0.22-audit-corrections.md).

## Validation and alternatives

Native algebraic oracles are separate from implementation replay validators.
MathWorks nominal Dugoff synthetic case Ck=10000,k=.01 returned Fx=101.0101,
while this approved variant gives99.0099. They cannot be relabelled equivalent.
MathWorks new creates defaults and modified Dugoff by default. Its optional
adapter must retain original family/variant and never fill user physical inputs.
Fiala, MF52 and MF62 public compute/TIR calls also succeeded in synthetic probes;
none is validated against an FS tire. No own complex TIR/MF/TTC fitting engine.
Test/runtime evidence and limitations will be recorded in v0.22-validation.md.

## Parameter catalogue and choices

| Component / field | Internal unit | Meaning |
|---|---|---|
| geometry.unloadedRadius_m | m | Unloaded outer radius, common library vertical source |
| geometry.width_m / rimRadius_m | m | Known geometric dimensions; not a force-law input |
| vertical.stiffness_N_per_m | N/m | Existing unilateral vertical law |
| force.parameters.Fz0_N | N | Positive reference load for reference/power laws |
| mu0 | 1 | Positive reference/constant effective friction, including road conditions |
| Calpha_N_per_rad | N/rad | Positive lateral reference stiffness |
| Ckappa_N | N | Positive stiffness per unit slip ratio |
| Cgamma_N_per_rad | N/rad | Signed small-camber thrust coefficient |
| n | 1 | Positive capacity load exponent, independent of stiffness exponents |
| pAlpha / pKappa | 1 | Declared lateral/longitudinal stiffness exponents |
| qGamma_per_rad2 | 1/rad^2 | Nonnegative symmetric capacity-loss coefficient |

Every scalar may be []. Geometry Only requires no force data. At nonzero camber,
camberThrust must be NEGLECTED or LINEAR_CONSTANT and camberCapacity NEGLECTED or
QUADRATIC. A constant stiffness/constant friction assumption is selected explicitly;
REFERENCE_ONLY has no tolerance-based extrapolation. Negative normal load is
invalid, zero contact is handled before ratios. A reference load is positive.
Frictionless mu0=0 is outside this native family's parameter domain, not inferred
from missing data. At invalid/overflowing demands NUMERICALLY_UNRESOLVED remains
unavailable rather than clipping. Domain has finite bounds for Fz_N,alpha_rad,
kappa,gamma_rad. MARK preserves all requested sample positions and NaN gaps;
REJECT refuses unavailable samples. No automatic resampling/truncation.

capabilities describes family support, not complete data. readiness returns
status/missing/diagnostics, sampleStatus N-by-3 and normalized request. evaluate
returns Fx_N/Fy_N/Mz_Nm arrays and the same status convention, exact states/order,
modelIdentity, family, frame, units, provenance, declared evidence and domain.
quality is N-by-3: ASSUMPTION_BASED or DECLARED_MODEL for available model outputs,
PHYSICAL_ZERO for no contact and NOT_AVAILABLE otherwise. It is separate from
availability/validity; the UI displays both per channel. Assumption tagging is
conservative for the declared model and never an uncertainty probability.
No analytical Jacobian, confidence interval or experimental validation is exposed.
Tests differentiate the equations independently to verify local slopes.

## Why this implementation

The approved reduced Dugoff provides shared longitudinal/lateral capacity using
few explicit parameters, suitable for hypothesis comparisons. Fiala lateral is
an appropriate alternative but its lateral equation alone does not define the
whole combined-slip workflow. Adding another reduced tanh family now duplicates
similar preliminary capabilities without data to choose between them. Full MF
needs far more coefficients and validity evidence; no own MF implementation or
TTC identification chain is justified by the available data. MathWorks APIs
already supply those complex tools and are reused optionally, not reimplemented.
These are current design decisions, not reconstructed historical motivations.

The contact frame x is the wheel-plane/road-plane intersection, oriented by the
supplied forward heading; y=z cross x. Gamma comes from the upward direction in
the actual wheel plane. Non-nominal steering/pose never uses only sideSign*camber.

## Optional provider API and scope

importMathWorksTir(file,sourceNote) returns a plain descriptor preserving original
text, provider-interpreted parameters, family/variant, package/MATLAB versions,
identity and IMPORTED_UNVERIFIED evidence. Import may normalize/fill internally:
it does not prove source completeness or known/calibrated parameter status.
FITTYP6 in the tested provider export is MF52; FITTYP62 is MF62. Other signatures
are rejected unless explicitly supported. No custom TIR parser is used.

evaluateMathWorks(descriptor,states) is a public optional contrast utility, not
the native project engine. It requires explicit ISO/SI Fz,alpha,kappa,gamma,Vx,
IP,psidot,omega channels with scalar expansion, reconstructs a temporary original
file via the public importer and returns only Fx/Fy. It rejects declared bounds
and forward speeds below VXLOW. MF52 has no inflation-pressure sensitivity;
its auxiliary IP does not create such a capability or an experimental domain.
Temporary folders are unique, checked inside tempdir and removed on completion.
Descriptors/results may be saved as plain MAT values without retaining the
source file; evaluation requires the add-on, native functionality does not.
No handles are persisted and no provider implementation is redistributed.

This API-only integration does not add a provider-model editor/import button,
MF project scenarios, calibration UI or TTC data processing to v0.22. The native
Tires interface covers the complete approved Generic/Custom workflow. Physical
uncertainty remains unknown unless documented by the user; no percentage is made up.

## Sources

- Dugoff, Fancher and Segel, An Analysis of Tire Traction Properties and Their
  Influence on Vehicle Dynamic Performance (1970), DOI10.4271/700377. The native
  descriptor names the specific reduced convention/extensions, not every historical
  Dugoff variant or the distinct MathWorks implementation.
- MathWorks R2026b public tireModel.new/compute/import/export/struct and tireData
  documentation; Extended Tire Features26.2.3 actual synthetic probes. The exact
  operational evidence is recorded separately in v0.22-validation.md.
