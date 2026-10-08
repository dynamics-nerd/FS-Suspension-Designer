# Spring, Damper & Wheel-Rate Modelling — v0.8

## Scope and assumptions

Optional ideal **COILOVER** associated with one validated ActuationGeometry.
The spring and damper share axial displacement, but their absolute lengths
are not equated. Rigid mounts and coaxial, fixed-offset spring seats are
assumptions of the requested model. The spring is linear, compression-only;
the damper is memoryless and passive. Inputs are prescribed kinematic paths
and velocities, not results of a force-balance or dynamic simulation.

All existing coordinate conventions, schemas and solvers are preserved:
X rear, Y right, Z up; positive wheel travel is bump. Sources may belong to
FL, FR, RL or RR; each mechanical model has its own parameters and identity.
Metadata should record KNOWN/ASSUMED and sourceNote per parameter. Missing
provenance does not make a value known. Example parameters are explicitly
ASSUMED and are not a Formula Student setup recommendation.

## Public API

```matlab
model = fsd.model.createSpringDamperModel(actuation, definition, units);
fsd.model.validateSpringDamperModel(model);
identity = fsd.model.springDamperIdentity(model);
fsd.model.validateSpringDamperIdentity(identity);

r = fsd.analysis.analyzeSpringDamperSweep( ...
    model, actuation, actuationSweep, actuationSweepAnalysis, wheelVelocity, velocityUnit);
fsd.analysis.validateSpringDamperSweepAnalysis(r, model, actuation);

s = fsd.analysis.analyzeSpringDamperState(model, actuationResult, damperVelocity, velocityUnit);
fsd.analysis.validateSpringDamperStateAnalysis(s, model);

p = fsd.analysis.analyzePrescribedSpringDamperPath( ...
    model, wheelTravel, damperCompression, wheelVelocity, pathUnits);
fsd.analysis.validateSpringDamperSweepAnalysis(p, model); % explicit ideal path
h = fsd.analysis.plotSpringDamperSweep(r, model, actuation, figureHandle);
```

The production sweep explicitly receives ActuationGeometry because the
existing v0.7 aggregate validator requires it. This does not duplicate that
geometry in SpringDamperModel. It consumes the matching validated v0.7 MR;
it does not rerun suspension or rocker solves. Other independent coordinates
are fixed by the BumpSweepResult source contract.

Sweep wheelVelocity may be scalar (broadcast) or one finite value per sample,
in input order. Omitted velocity is prescribed rest (0 m/s), not a computed
velocity. Single-state damperVelocity is an **axial compression velocity**,
not wheel velocity; its default is also prescribed rest. Single states have
no validated MR: wheel force, rate and wheel damping metrics remain NaN.

The prescribed-path API is a distinct source kind, PrescribedDamperPath.
It requires real, finite matching z/c vectors and explicit units. It derives
both MR and dMR/dz from this ideal one-dimensional path. Nominal c at an
explicit z=0 must be zero within roundoff and damper length must remain
positive. It neither fabricates an ActuationResult nor asserts that the path
is attainable by the associated physical rocker. All other coordinates are
assumed fixed; this assumption must accompany any use outside the benchmarks.

## Model definition and units

```matlab
definition.configuration = "COILOVER";
definition.spring = struct("modelType","LINEAR_COMPRESSION", ...
    "rate",30000,"freeLength",0.20,"preloadCompression",0.02);
% Optional: definition.spring.solidHeight = 0.12;
definition.damper = struct("modelType","LINEAR_ASYMMETRIC", ...
    "compressionCoefficient",1500,"reboundCoefficient",2500);
% Optional: definition.damper.minimumLength / maximumLength;
definition.metadata = struct("sourceKind","ASSUMED", ...
    "sourceNote","Example parameters only");
units = struct("length","m","springRate","N/m", ...
    "dampingCoefficient","N*s/m","velocity","m/s");
model = fsd.model.createSpringDamperModel(actuation,definition,units);
```

For TABULATED_FORCE_VELOCITY, use compressionTable and reboundTable instead
of the two coefficients. Each is N×2 [nonnegative speed magnitude, force
magnitude in N]. At least two rows, first row exactly [0,0], strictly increasing
speed, real finite nonnegative values. Force need not be monotonic:
digressive/nonmonotonic curves can still be passive. All four unit tokens
are validated, including tokens not used by a particular law.

Canonical core units: m, m/s, N, N/m, N*s/m, J, W.
Public conversion helper:

```matlab
y = fsd.model.convertMechanicalUnits(value, quantity, fromUnit, toUnit);
```

| quantity | Allowed unit tokens | Conversion to SI |
|---|---|---|
| length | m, mm | mm × 0.001 |
| velocity | m/s, mm/s | mm/s × 0.001 |
| springRate, wheelRate | N/m, N/mm | N/mm × 1000 |
| dampingCoefficient | N*s/m, N/(mm/s) | N/(mm/s) × 1000 |

The literal N*s/m denotes N·s/m. Forces in tables are always N. Conversions
are explicit at factory/input/plot boundaries, not inside constitutive laws.
NaN output curves are preserved by plotting only converting finite entries.

Model spring fields: modelType, rate_N_per_m, freeLength_m,
preloadCompression_m, solidHeight_m. Rate and free length must be positive;
preload is nonnegative and less than free length (positive nominal seat
separation). Solid height, if supplied, is positive and less than free length.
Damper fields: modelType, compressionCoefficient_Ns_per_m,
reboundCoefficient_Ns_per_m, compressionTable, reboundTable,
minimumLength_m, maximumLength_m. Unused law data and absent optional bounds
are normalized to []. Coefficients are nonnegative; lengths positive and
minimum <= maximum. Nominal outside provided bounds is diagnosed during
evaluation rather than implicitly repaired.

Model schema 0.8.0 contains cornerId, actuationIdentity, configuration,
spring, damper, derivedStaticGeometry, metadata, identity. Identity schema
1.0.0 includes association, complete mechanical parameters/curves/bounds and
derived geometry; metadata is excluded. No hash or hidden state.

## Coilover seat geometry, preload and energy

```text
Lseat,0 = Lfree-xPreload
seatOffset = Lseat,0-Ldamper,0         (signed, no imposed sign)
c = Ldamper,0-Ldamper
Lseat = Ldamper+seatOffset = Lseat,0-c
xRaw = xPreload+c
x = max(xRaw,0)
gap = max(-xRaw,0)
Lspring = Lfree-x
Fs = k*x
U = 0.5*k*x^2
```

The actual ideal spring returns to free length when unseated: seat separation
can exceed spring length and the gap is explicit. It never carries tension.
Fs, x and U are zero in the unloaded branch. At xRaw=0, engagement has no
unique bilateral stiffness; tangent outputs are NaN, not an arbitrary k.
A roundoff band snaps this boundary to zero (see numerical policy below).
The nominal preload force k*xPreload is axial, not wheel load, sag or weight.
No equilibrium is inferred from the static/nominal geometry.

## Signed virtual-work projection and full wheel rate

For a smooth engaged path:

```text
MR = dc/dz
springWheelResistance = dU/dz = Fs*MR
wheelRateElastic = k*MR^2
wheelRateGeometric = Fs*dMR/dz
wheelRateTotal = d(Fs*MR)/dz = wheelRateElastic+wheelRateGeometric
```

These are generalized resisting quantities. Actual applied spring force
on z is the negative of springWheelResistance; it is not a tire contact
load. MR, not abs(MR), is required for force/velocity transfer.
Constant MR removes the geometric term, so preload cannot change wheel rate
on the compressed branch. Variable MR makes preload affect that term.
Zero MR does not necessarily mean zero wheel rate if curvature and Fs exist.

Total tangent wheel rate may be negative. It is not clamped; the separate
NEGATIVE_TANGENT_STIFFNESS diagnostic does not determine stability of the
complete vehicle. Unseated states have zero spring resistance, energy and
wheel rate away from engagement, provided the path derivative is valid.
Damping can remain active with the spring unseated.

## Numerical derivatives

Achieved z is the differentiation coordinate; requested z must also be
strictly monotonic, with no sorting or removal of duplicates. At least three
samples are required. A local quadratic uses three centered neighbors in
interiors and the first/last three at endpoints, including descending and
nonuniform grids.

Set h=max(abs(zNeighbor-zCurrent)), t=(zNeighbor-zCurrent)/h. Solve
[1,t,t²]*q=cNeighbor-cCurrent and compute dMR/dz=2*q(3)/h² directly
from **original compression**, not by differentiating the approximate MR.
Production MR is the validated v0.7 first derivative, subject to its own
first-derivative sensitivity check. Prescribed-path MR uses q(2)/h.
Unresolved curvature alone never suppresses an otherwise resolved MR.

This is exact for a quadratic. Second-derivative truncation is O(h²) in
uniform interiors but generally O(h) at endpoints/arbitrary nonuniform
stencils. No universal second-order claim or uncertainty bound is made.
An engineering accuracy decision for a new geometry requires a convergence
study; the benchmark is not a validation of every real linkage.

Numerical policy (not manufacturing tolerances):

- spacing <= 64*eps(max(abs(zStencil),1 m)) suppresses the stencil;
- rcond of the normalized interpolation matrix <= sqrt(eps) suppresses it;
- an upstream isIllConditioned sample suppresses any touching stencil;
- no stencil crosses a failed/not-attempted sample. Curvature diagnostics can
  remain available on contiguous valid stencils. Production MR retains v0.7's
  source availability: a globally unavailable source MR is never restored;
- contact/boundary classification uses 64*eps(max(relevant SI lengths,1 m));
  no mechanical clearance or spring law is inferred from this band.

### F-01: representation sensitivity, independently of matrix conditioning

A normalized interpolation matrix can be well conditioned while division by
h squared amplifies tiny errors in its original compression samples. F-01
adds sensitivity weights, not a universal minimum-spacing rule. With stencil
abscissae x1,x2,x3 and evaluation point z, for the other two indices j,l:

```text
w1_i = (2*z-x_j-x_l)/((x_i-x_j)*(x_i-x_l))
w2_i = 2/((x_i-x_j)*(x_i-x_l))
s = max(abs(candidateMR), abs(diff(c)/diff(z))) over the stencil
e_i = eC_i+s*eZ_i
E_MR = sum(abs(w1_i)*e_i)+16*eps(abs(candidateMR))
E_curvature = sum(abs(w2_i)*e_i)+16*eps(abs(candidateCurvature))
```

Weights are evaluated in centered/scaled coordinates. For production MR,
E_MR additionally includes abs(validatedSourceMR-stableQuadraticMR), and
the validated source value is the candidate actually used for projection.
No second differentiation of approximate MR is introduced.

Sample error proxies, all in canonical SI:

- Prescribed path: eC=16*eps(abs(c)), eZ=16*eps(abs(z)). These describe only
  stored floating-point inputs, not experimental or user-data uncertainty.
- Production: let S be the largest absolute static/current damper mount,
  current suspension attachment or upstream state coordinate; let
  r=max(abs(upstream lengthErrors_m))+abs(actuationRodLengthResidual_m),
  chi=max(actuation conditioning,sqrt(eps)). Add
  16*(eps(Ldamper,0)+eps(Ldamper))+(16*eps(S)+r)/chi to eC, and
  16*(eps(abs(currentWheelCenterZ))+eps(abs(staticUprightReferenceZ)))+r
  to eZ. The dimensional length residuals are indicators, NOT a bound on
  position error. The dimensionless solver residualNorm is not used as metres.

For engaged spring force F and rate k, propagate the local estimates:

```text
E_F = k*eC_current+16*eps(abs(F))
E_geometric = abs(F)*E_curvature+abs(curvature)*E_F
              +E_F*E_curvature+16*eps(abs(F*curvature))
E_elastic = k*(2*abs(MR)*E_MR+E_MR^2)       (zero if unseated)
E_Kw = E_elastic+E_geometric+16*eps(abs(candidateKw))
T_MR = 1e-6+1e-3*abs(MR)
T_curvature = 1e-6/Lfree+1e-3*abs(curvature)
T_Kw = 1e-6*k+1e-3*abs(candidateKw)
```

The absolute floors use the model's positive free spring length and rate,
not invented vehicle dimensions. Numerical policy F01-1 uses 16 ulps as a
short-arithmetic allowance, 0.1% relative estimated perturbation budget and
one part per million natural-scale absolute floor. These are deterministic
software quality budgets, not manufacturing tolerances or confidence levels.
Zero curvature is allowed by the absolute floor. Using total Kw rather than
the sum of absolute components exposes elastic/geometric cancellation.

MR passes independently if its estimate is finite and E_MR<=T_MR.
Curvature passes only if both E_curvature<=T_curvature (intrinsic quality,
independent of preload/force) and E_Kw<=T_Kw (projected impact), with finite
estimates and the pre-existing guards satisfied. A small/zero spring force
cannot conceal unresolved curvature. The conservative rule also applies
to unseated states. It never replaces total stiffness with elastic stiffness.

These estimates are **not rigorous bounds**: 16 ulps is a heuristic allowance;
abscissa propagation is first-order; residuals need not bound positional error;
truncation, branch sensitivity beyond the proxy, manufacturing and measurement
errors are not estimated. AVAILABLE means this numerical policy passes, not
that the complete derivative error is below its budget. Convergence studies
and independent physical validation remain necessary.

## Damping and passivity

```text
vd = MR*vWheel
vd>0: compression branch
vd<0: rebound branch
linear: Fd=cBranch*vd
tabulated: Fd=sign(vd)*interp1(branchSpeed,branchForce,abs(vd))
damperWheelResistance = MR*Fd
Pdamper = Fd*vd = damperWheelResistance*vWheel >= 0
```

Fd denotes signed resistance; actual applied damper force is -Fd.
Negative MR reverses damper branch relative to the wheel velocity, without
changing passivity. Linear wheel coefficients per damper branch are
cCompression*MR² and cRebound*MR²; they are **not** mislabeled as wheel
compression/rebound branches. The local coefficient uses the selected axial
branch. At zero velocity force and power are zero; for unequal coefficients
the local bilateral slope is NaN, while both branch coefficients are available.
With equal coefficients the common slope is available.

Tables are piecewise linear, include zero, and do not extrapolate. Beyond the
selected branch speed range, force, power and local coefficient are NaN with
DAMPER_VELOCITY_OUT_OF_RANGE; spring stiffness can still be available.
At internal knots the local slope is NaN. A decreasing force segment can have
negative local slope while still dissipating positive power. No hysteresis,
gas force, thermal behavior, friction or velocity inferred from a sweep
sampling interval is included. Damping never contributes to wheelRateTotal.

## Mechanical limits and statuses

| Family | Representative statuses and policy |
|---|---|
| Spring engagement | SPRING_COMPRESSED, SPRING_UNSEATED, SPRING_ENGAGEMENT_TRANSITION |
| Damper travel | UNKNOWN, WITHIN_PROVIDED_LIMITS, DAMPER_TRAVEL_LIMIT_EXCEEDED |
| Spring solid height | UNKNOWN, ABOVE_PROVIDED_SOLID_HEIGHT, COIL_BIND_LIMIT, COIL_BIND_EXCEEDED, INVALID_SPRING_SEAT_GEOMETRY |
| Damper law | COMPRESSION, REBOUND, ZERO_VELOCITY, DAMPER_VELOCITY_OUT_OF_RANGE, UNAVAILABLE_VELOCITY |
| Path derivative | AVAILABLE, UNAVAILABLE_INSUFFICIENT_SAMPLES, UNAVAILABLE_NONMONOTONIC_WHEEL_TRAVEL, UNAVAILABLE_PATH_GAP, UNAVAILABLE_ILL_CONDITIONED, UNAVAILABLE_NUMERICAL_RESOLUTION, UNAVAILABLE_NONFINITE_DERIVATIVE |
| MR quality | AVAILABLE, the applicable path failure, UNAVAILABLE_NUMERICAL_RESOLUTION, UNAVAILABLE_SOURCE_MOTION_RATIO |
| Wheel rate | AVAILABLE, SPRING_ENGAGEMENT_TRANSITION, COIL_BIND_LIMIT, UNAVAILABLE_MOTION_RATIO, derivative unavailability, UNAVAILABLE_MECHANICAL_LIMIT, UNAVAILABLE_ACTUATION_FAILURE |
| Tangent diagnostic | NEGATIVE_TANGENT_STIFFNESS, NONNEGATIVE_TANGENT_STIFFNESS, UNAVAILABLE |

A damper travel exceedance or post-solid-height compression keeps geometry,
seat/gap/compression and margins but suppresses constitutive forces/energy
and all projections. No end-stop force or post-bind stiffness is invented.
At the solid-height boundary the pre-limit force/energy is retained but the
bilateral tangent is unavailable. Nonpositive seat separation is infeasible
even if solid height was omitted.

feasibleRelativeToProvidedLimits means only no known provided bound was
exceeded. UNKNOWN bounds do not certify physical feasibility/safety.
Upstream failures execute no constitutive law. MR unavailable means no wheel
force/rate or damper response from wheel velocity, even at prescribed zero
wheel velocity; an explicit scalar axial-velocity call remains possible.

## Results, aggregation and integrity

State outputs contain geometry, seat separation, raw/actual spring compression,
spring free-gap and length, axial force/energy, bound margins and statuses,
MR and derivative/status, velocities, damper axial/wheel resistance, power,
local/branch wheel coefficients, elastic/geometric/total wheel rate,
wheelRateStatus and stiffnessDiagnostic. Scalar output keeps them under state.
Sweep results store N×1 states plus matching N×1 curve arrays.

Sweep-only derivativeDiagnostics stores the policy/version, per-sample eC/eZ,
resolution source kind, N×3 stencil indices and weights, normalized rcond,
raw candidate MR/curvature/Kw, error estimates and limits, MR status and
intrinsicCurvatureResolved/wheelRateImpactResolved flags. Raw candidates are
diagnostic evidence only: they MUST NOT be used as published reliable curves.
motionRatioStatus is separate from derivativeStatus, which gates curvature
and its wheel-rate impact. UNAVAILABLE_NUMERICAL_RESOLUTION means amplification
exceeds one of the documented budgets; NONFINITE means computation cannot
provide a finite estimate. SOURCE_MOTION_RATIO never overrides upstream NaN.

With unresolved curvature but valid MR, axial spring response, wheel force,
damper response and elastic component remain available subject to their own
mechanical/law limits; geometric and total rates are NaN and stiffnessDiagnostic
is UNAVAILABLE. Engagement and coil-bind tangent statuses retain precedence.
If MR itself is unavailable, wheel projections remain unavailable as before.

Source/result validation checks full upstream identities, corner association,
requested/achieved correspondence, source payload and matching MR analysis,
not just equal vector dimensions. Public result validators reconstruct all
mechanical fields/statuses/aggregates with private cores. Timing must be
finite and nonnegative; its exact value is not reconstructed. Velocities are
declared independent inputs, not cryptographically authenticated history.
A completely changed but physically consistent input describes a new valid
evaluation; identities are semantic contracts, not provenance signatures.

Nominal reference: only one requested z==0 sample with finite total wheel
rate. Otherwise nominal rate, geometric nominal contribution and rate migration
are NaN. Never choose nearest zero or first sample as an implicit reference.
Known nominal geometry is not an equilibrium solution.

Aggregate extrema require every relevant sample finite; otherwise they are
NaN rather than hiding unavailable samples. Metrics include maximum axial
spring force, maximum absolute spring wheel resistance, min/max tangent rate,
min/max damper length, maximum compression/extension, maximum spring energy,
absolute damper velocity/resistance, dissipated power and minimum bound margins.
Nominal total/geometric rate is published separately.
validWheelRateSampleCount and wheelRateCoverageComplete expose partial coverage.
Unavailable total rate propagates to its migration point; unavailable nominal
rate disables the entire migration. Whole-path extrema never summarize only
the finite subset. Plots preserve gaps and do not join through invalid values.
Validators reconstruct the diagnostics, coverage, flags, states and aggregates
with the same private numerical policy: changing a flag alone cannot authorize
a fabricated finite rate. Pre-F01 stored mechanical analyses require reanalysis
from their preserved source; no silently trusted legacy diagnostic payload.

## Integration and plots

Independent corner models consume asymmetric axle, body-roll and steering
ActuationResults through the axial-only API. They use the actual current
damper length; no roll stiffness or wheel derivative is inferred along a
mixed-coordinate path. A future fixed-rack steering/bump derivative requires
a separately specified path contract; it is not silently treated as a bump
sweep. PUSHROD/PULLROD share constitutive laws but identities remain distinct.
No rod structural force follows from these axial coilover quantities.

plotSpringDamperSweep validates its input and produces one 3×3 layout:
spring compression, axial spring force, spring wheel resistance, total rate,
elastic/geometric components, damper length, spring energy, axial velocity
versus resistance, and wheel velocity versus damper wheel resistance.
It preserves NaN gaps, shows limits, and marks unseated/engagement/infeasible
samples. Two example figures separate normal and deliberately limited models.

## Independent validation cases

The principal benchmark uses c=a*z+b*z², not the production rocker solver:

```text
MR=a+2*b*z; dMR/dz=2*b
Fs=k*(preload+c)                     (engaged)
Fw=Fs*MR
Kw=k*MR^2+2*b*Fs
```

Tests cover a=0.5, b=3 1/m, k=30000 N/m, preload 0/0.02 m and z negative,
zero, positive on uniform/nonuniform/decreasing grids. At preload=0.02 m,
z=0: Fs=600 N, Fw=300 N, elastic=7500 N/m, geometric=3600 N/m,
total=11100 N/m. These are test values, not vehicle targets.
MR-constant tests use two preloads and verify unchanged rate. Independent
central differences of analytical U and Fw verify energy gradient and tangent.
Negative-MR damping tests verify branch, signed force, equal powers and
passivity. Real sources cover tangency, failure gaps, roll± and steering.

## Exclusions and future decisions

No full-vehicle equilibrium, sag, actual corner load, tire/aero forces, ride
frequency, damping ratio, coupled dynamics, ARB, nonlinear/bump-stop/heave/
third/torsion springs, hysteresis, thermal model, rod stress/buckling/fatigue,
anti-geometry, optimization, rules, packaging collisions, Adams or App Designer.

ARB INTEGRATED | POST_DESIGN | DISABLED is unchanged. Longitudinal anti-dive,
anti-lift/anti-rise and anti-squat remain future specifications. NM-001/NM-002
remain resolved. No blocking physical OPEN DECISION was introduced for the
explicitly requested ideal model. Any real end-stop/post-bind law, nonlinear
spring or gas/hysteretic damper is an OPEN DECISION for a future authorized
milestone, not a default silently selected here.
