# Anti-Roll Bar & Axle Coupling — v0.23 contract

Status: implemented and developer-validated, 25 October 2026. Stable base v0.22.0,
044aa1ea0c899f41146c015ee6e190b63d6829a7. No independent audit acceptance implied.

Audit update 26 October 2026: user reports independent closure of V23-F-01 and
a new MEDIUM V23-F-02 (unchanged ROLL Apply rewrites canonical declarations).
Focused correction developer-validated (45/45 selected PASS), pending independent re-audit.
Core physical contracts below remain unchanged. [Current correction](v0.23-f02-validation.md).

### Loaded ARB study editing boundary (V23-F-02)

ArbView snapshots the complete canonical scenario definition and the rendered
controls after programmatic loading. Apply starts from that definition and
converts only fields whose presentation differs exactly from the snapshot.
Unchanged fields retain class, shape, cell contents, source metadata and missing
fields. Solver options and other unrepresented scenario fields survive Apply.
Roll/heave and the two driver paths are independent edits. Prescribed samples
are one homogeneous N-by-2 numeric field; when a column is edited, the unchanged
column comes directly from the canonical values, without another unit round-trip.
Packaging merges changed controls/cells and retains unrepresented volume fields.
Restoring the original presentation restores the original declaration, without
floating-point tolerances. State clears on reset/study load and refreshes after
Apply/LOAD. No persistent data model or physical compatibility rule changes.
Readiness still updates on an unchanged Apply; existing revision/STALE machinery
acts normally for real edits. Explicit engine changes create the new engine's
plan/options as before; unchanged resource references remain canonical.

### Sizing presentation boundary (V23-F-01)

Sizing target declarations can retain valid integer/single/double input types.
ArbView converts to double **before** multiplying by pi/180, and formats17
significant digits. An unchanged loaded target cell retains its original numeric
declaration; an unchanged whole target table retains the exact original plan,
including absent fields of partial configurations. Editing provenance alone
retains the numeric declaration. Real numeric edits parse as double and convert
back to SI. The loaded plan/rows are transient presentation state, cleared when
loading another study/resetting, never added to MAT/project/worker schemas.
The analogous loaded wheel/driver travel, ROLL angle and heave controls also
promote to double before unit arithmetic. Core result/parameter displays already
consume canonical double outputs; numerical equations and readiness do not change.

## Resource and units

AntiRollBar is a plain SI resource in fsd.model, with immutable project revisions.
Representations EQUIVALENT_LINEAR and COAXIAL_TORSION are distinct capabilities.
Unknown numeric parameters are [], not zero. Each available parameter has explicit
sourceKind/sourceNote. Numeric inputs normalize safely to full double before
identities; unsafe integer conversions and nonfinite declarations are rejected.
Canonical internal frame remains X rear/Y right/Z up; points are rows.

## Energy and signs

Equivalent: delta = weights' * [zL;zR] - deltaFree [m], U=.5*kLinear*delta^2.
Weights are dimensionless declared displacement ratios, associated with this
particular equivalent coordinate. Both are nonzero. The resource does not infer
these ratios from a roll-stiffness scalar. No physical shaft torque, arms, link
force or packaging is attributed to this representation.

Geometric: psi=alphaR-alphaL-psiFree [rad], T=kTheta*psi, U=.5*kTheta*psi^2.
Positive elastic torques on arms are [+T;-T] about the COMMON oriented shaft axis.
For either coordinate x, resistance r=dU/dz=k*x*dx/dz; applied generalized force
Q=-r. Tangent K=k*(dx/dz)*(dx/dz)'+k*x*d2x/dz2. The geometric term is retained.
Individual diagonal rates describe opposite-wheel-fixed conditions; a modal rate
requires an explicit path z(s), including d2z/ds2 if nonzero. Secant incremental
rate is undefined for zero modal increment. It is not the tangent by definition.

Arms/links/shaft are an elastic mechanism reduction without their own dynamic
inertia or separate gravity energy. Existing declared vehicle mass and CG remain
the global mass accounting; there is no inferred ARB density/mass distribution.

## Reference and preload

referenceMode UNKNOWN blocks mechanical evaluation. DECLARED_FREE consumes the
explicit freeDeflection_m (equivalent) or freeAngle_rad (torsional).
ZERO_AT_INSTALLATION consumes installationWheelTravel_m for equivalent, giving
deltaFree=weights'*zInstall. Geometric arm points define the installed reference
pose; installationAngles_rad supplies the coordinates assigned to those two
arms. A solved closure rotation beta_i is added to that coordinate. Consequently
psiFree=installationAngles(2)-installationAngles(1), which need not be zero.
This mode asserts an unloaded installation explicitly, never from a missing value.
The geometric links must close in that installed pose against the selected native
driver's static point; otherwise installation is inconsistent. Preloaded heave
can preserve torsion while still carrying nonzero torque and forces.

## Constitutive routes

KNOWN consumes kTheta_Nm_per_rad and stiffnessScope SHAFT_ONLY/EFFECTIVE_PORTS.
CIRCULAR_SHAFT consumes G_Pa, effectiveLength_m and circular section: J=pi*D^4/32
for SOLID, or pi*(Do^4-Di^4)/32 for TUBULAR, kTheta=G*J/L. Active calculated mode
does not also admit a known kTheta value. Material geometry stored in KNOWN mode
is not silently consumed. No flexible arms/blades/supports, bent-bar flexibility,
noncircular torsion, fatigue or strength certification follows from this formula.
Inverse sizing solves this same scalar law for an explicitly requested stiffness.
L_eff is an explicit constitutive active-span declaration, not automatically the
support separation or the displayed capsule length. Its port/end-condition
interpretation must be justified by the user's data; the application does not
infer or certify the real boundary conditions from the simplified centre line.

## Geometry and numerical path

Coaxial arms rotate about the declared chassis-fixed oriented axis. Independent
ROCKER/UPRIGHT/UCA/LCA pickup points are declared, not copied from damper pickups.
Each rigid articulated link gives |P_i(beta)-S_i|^2=ell_i^2. Reuse the historical
circle/sphere classification and continuation; no new suspension solver.

For prepared continuous evaluation, interpolate native DRIVER POINT positions
and use the same closed-form circle/sphere closure on that sampled path. Implicit
derivatives of the same closure supply beta' and beta'', hence energy derivatives.
This avoids interpolating force/torque/rate independently or leaving a link-length
gap by interpolating arm angle and driver point separately. It remains explicitly
SAMPLED_DRIVER_PATH_APPROXIMATION, not continuous exact suspension kinematics.
Only scalar analytic closure arithmetic runs inside the global energy evaluation;
native suspension/actuation generation and validation run during preparation.
Branches/segments/singularities/limits remain guards. No extrapolation or clipping.

## Global integration and integrity

Add front/rear energies to historical U, with gradient/Hessian embedded in the
four body-relative wheel coordinates. Chassis-fixed internal deformation has no
extra direct phi spring at fixed z. Internal forces do not enter the external
world balance twice. A no-contact wheel remains mechanically connected.
Keep historical no-ARB schemas/data exactly; an optional versioned coupling extends
active systems. Newton, scaling and selection semantics remain historical, with
additional segment/branch guards. Contact transitions and unavailable bilateral
curvature do not certify smooth stability.

Exact execution snapshot/revision and RF-01/02/03 stay authoritative for worker
acceptance. A separate structural physical consumption projection decides reuse.
No global cache, alternate MAT writer or recursive result ledgers are introduced.
ARB-001 INTEGRATED still refers to future joint optimization; global physical
integration does not complete that requirement. Original historical motivations
not present in documentation remain pending reconstruction.

## Public API and resource contract

| Package | APIs / responsibility |
|---|---|
| model | createAntiRollBar, validateAntiRollBar, antiRollBarParameterCatalog, antiRollBarReadiness, antiRollBarDependencies |
| geometry | circleSphereRotation (shared historical algebra), antiRollBarClosure, antiRollBarPoints (declared/sample point aliases) |
| kinematics | antiRollBarDriverPoint, solveAntiRollBar, solveAntiRollBarSweep, validateAntiRollBarState |
| analysis | antiRollBarStiffness, evaluateAntiRollBarTorsion, sizeAntiRollBarSection, prepareAntiRollBar, validatePreparedAntiRollBar, evaluateAntiRollBar, analyzeAntiRollBarSweep, evaluateAntiRollBarKinematics, analyzeAntiRollBarKinematicSweep, antiRollBarModalResponse, antiRollBarSecantResponse, compareAntiRollBarResponses |
| packaging | createAntiRollBarDefinition, validateAntiRollBarDefinition, evaluateAntiRollBar |
| project | registerAntiRollBar, findAntiRollBar, assignAntiRollBars; native prepare/run/readiness/resultCompatibility and MAT APIs |

`createAntiRollBar` takes a scalar definition. Text defaults express unavailable
choices, not physical defaults. Metadata: id/name/revision/axleId,
representation/referenceMode/stiffnessMode/stiffnessScope/section, drivers(2),
adjustmentId, parameters, provenance, referenceFrame, note. `revision` is assigned
by the project registry when registering a new definition. Direct core construction
defaults revision1. IDs are canonical uppercase identifiers. Parameter catalog:

| Parameter | Shape | SI meaning |
|---|---|---|
| weights | 2×1 | dimensionless equivalent-coordinate coefficients |
| linearStiffness_N_per_m | scalar | stiffness in that equivalent displacement coordinate |
| installationWheelTravel_m | 2×1 | explicitly unloaded installed wheel coordinates |
| freeDeflection_m | scalar | explicit free equivalent displacement |
| axisPoint_m / axisDirection_unit | 1×3 each | chassis-fixed point and common oriented unit axis |
| supports_m | 2×3 | explicit support centres on that axis; absence does not block force/closure |
| armPoints_m / driverPoints_m | 2×3 each | left/right installed arm tips and independent material pickups |
| linkLengths_m | 2×1 | rigid link lengths |
| installationAngles_rad | 2×1 | angular coordinate labels of the installed arm geometry |
| freeAngle_rad | scalar | free relative angle, not individual zero labels |
| kTheta_Nm_per_rad | scalar | known constitutive stiffness at declared ports |
| G_Pa / outerDiameter_m / innerDiameter_m / effectiveLength_m | scalar each | declared shear modulus and active circular span |
| wheelTravelDomain_m / armAngleDomain_rad | 2×2 each | [min,max] for left/right |
| twistDomain_rad / deflectionDomain_m | 1×2 each | relative deformation domain |

Every numeric value is finite real double after safe normalization; [] remains
unknown. Nonempty parameters require sourceKind KNOWN/ASSUMED/DERIVED/FIXED and
nonblank sourceNote. Unit axis is normalized once; zero direction is invalid.
No tolerances are material properties. Complete native frame id/origin/axis
convention must match selected suspension parents. Points are chassis coordinates;
they are not axle-local values automatically translated from track dimensions.

GEOMETRY requires actual geometry/drivers/frame and wheel/angle domains, not
constitutive stiffness/free reference or material support radii. MECHANICAL adds
the consumed law, reference and deformation domain. STIFFNESS and TORSION can
evaluate the declared constitutive relation without a fabricated mechanism.
SIZING project readiness needs only G/L/section/(Di) plus a sourced user target.
Known invalid shapes, installed closure, dimensions or options are INVALID_INPUT;
absent data is MISSING_DATA; an equivalent geometric request is UNSUPPORTED.

## Closure derivation, branches and driver paths

Let unit axis e, point O, installed tip P0. Its axis station is
C=O+e[e·(P0−O)], radial vector u=P0−C, v=e×u. Then
P(β)=C+u cosβ+v sinβ, Pa=e×(P−C), Paa=e×Pa.
For driver S and length ell, |P−S|²=ell² becomes
A cosβ+B sinβ=D, where A=2(C−S)·u, B=2(C−S)·v,
D=ell²−|C−S|²−|u|². The shared historical circle/sphere kernel classifies
two solutions, tangent, no intersection, all angles and inconsistent degeneracies.
It chooses the nearest unwrapped reference angle. The branch label is sign(gβ),
where g=|P−S|²−ell². A branch mismatch, ill conditioning or closure/angle limit
cannot become AVAILABLE. Sweep continuation carries the previous accepted angle
and branch; failed source samples separate connected segments.

ROCKER rotates the independently declared material point about the existing
rocker axis using its solved angle. UPRIGHT uses the native rigid upright pose;
UCA/LCA reuse the existing material-point transforms. No fictional rocker or
coilover motion ratio is introduced. Native scalar `solveAntiRollBar` retains
the parent source values; canonical state validation reconstructs its closure.

Preparation consumes one ordered native BUMP path per side, plus its actuation
sweep only for ROCKER. Source samples must be converged and admissible. An
explicit ASSUMED `PrescribedArbDriverPath` exists for analytical benchmarks;
the project/UI production path uses actual native sources. PCHIP interpolates
three coordinates of S(z) and an angular continuation guess inside each connected
segment. The angular guess selects closure; it is not independently interpolated
elastic geometry. Invalid samples and branch transitions are never bridged.

A historical IDEAL_PRESCRIBED_3D coilover/WC benchmark alone does not supply
actual rocker or arbitrary material-point poses for a geometric global bar.
That combination is rejected explicitly; equivalent global bars can use the
historical ideal fixtures, and standalone prescribed ARB driver paths must carry
their separate ASSUMED provenance. Production project paths retain native poses.

For the same interpolant/closure, let w=P−S, S'=dS/dz, S''=d²S/dz²:

```
gβ  = 2 w·Pa                 gz   = −2 w·S'
gββ = 2(Pa·Pa+w·Paa)         gβz  = −2 S'·Pa
gzz = 2(S'·S'−w·S'')
β'  = −gz/gβ
β'' = −(gzz+2*gβz*β'+gββ*β'^2)/gβ
```

Only these analytic arithmetic operations run inside the global energy loop.
This is an approximation to the native sampled path, not an exact continuous
suspension solve. At internal PCHIP knots the one-sided Cartesian second
derivatives must agree under the historical WC position-curvature budget
`1e-6 + 1e-3*max(abs(left),abs(right))`, dimensionally in m/m². Endpoints,
unresolved knots and active deformation/angle limits cannot establish bilateral
curvature. The 64-ulp arithmetic bands and existing numericTolerances distinguish
floating-point degeneracy/postcheck from a user physical domain; limits themselves
are not enlarged or clipped. No claim is made of experimentally calibrated bounds.

## Virtual work and observable rates

For geometric paths a=[−alphaL';alphaR'], C=diag(−alphaL'',alphaR'').
The energy gradient is r=T*a, elastic K=kTheta*a*a', geometric K=T*C.
Applied wheel generalized forces are −r. The constitutive arm torques are
tau=[+T;−T]. For link direction n=(S−P)/ell, moment arm h=e·[(P−O)×n],
the link axial force is lambda=−tau/h; lambda>0 denotes tension acting from
tip towards driver. Force on the driver is −lambda*n. This satisfies virtual
work on the moving pickup and closes each arm torque balance. Singular or
ill-conditioned h is unavailable, not a large trusted link load.

For KNOWN/EFFECTIVE_PORTS, T is the torque of the declared condensed law at its
ports; it is not automatically a material shaft stress/torque certificate.
The circular GJ/L route is SHAFT_ONLY. No flexing of arms/supports or blade law
is hidden in that route. Reaction forces at physical supports are not calculated.

For an explicitly declared path z(s), generalized modal resistance is
R_s=z'ᵀr and tangent K_s=z'ᵀKz'+rᵀz''. A straight path has z''=0 only when
declared so. Diagonal Kii is opposite-wheel-fixed, KLR is coupling, and
`[-1;1]'*K*[-1;1]` refers specifically to that wheel-displacement parameter,
not automatically body roll. A roll path in radians has K_s in Nm/rad; multiply
by pi/180 for Nm/deg. Linear modal K in N/m is divided by1000 for N/mm.
Incremental secant between two compatible responses is
`z'ᵀ(r2−r1)/(s2−s1)` for the declared linear trajectory; the coordinates must
match that increment and the resource identity. Zero increment is undefined.

`candidateTangent_N_per_m` retains the algebraic local curvature. Public tangent
is NaN when bilateral curvature is not available, with explicit tangentStatus.
Forces/energy may remain inspectable there. GLOBAL_STATIC uses the candidate for
its historical numerical machinery but propagates the bilateral flag, preventing
an unsupported smooth-stability classification. A converged stationary point,
admissible root and selected stable alternative remain distinct concepts.

Prepared paths retain per-source closureStates/statuses. A response retains
closureEnds, including an unavailable queried closure when one was computed;
unattempted/missing-source ends stay empty. This preserves residual, conditioning,
branch and raw classification rather than replacing a failure with a valid pose.
Desktop's stored sample index selects these diagnostics independently of whether
a modal path has been declared; closure residual is presented in mm.

## Section sizing and comparison

Inverse circular sizing uses `Do=(Di^4+32*L*kTarget/(pi*G))^(1/4)`.
Three-argument sizeAntiRollBarSection explicitly means SOLID (Di=0); TUBULAR
needs a positive known Di in project configuration. Positivity, Do>Di, finite
representability and safe numeric conversion are checked. G, effective length
and target/provenance come from the user. This does not infer a modulus or an
optimal chassis roll stiffness. The returned diameter is a preliminary scalar
design result, not an automatic adoption or a manufacturing prescription.

Changing material/diameter/length, port stiffness, arm positions, pickups or a
discrete adjustment creates an immutable resource revision (or another ID).
Run the same ordered wheel conditions, retain both results and compare curves.
Matching a nominal rate never establishes physical equivalence. The comparison
utility returns both identities and only subtracts available common conditions;
it preserves assumptions/native parent paths rather than declaring them equal.

## Project actions, reuse, worker and persistence

New UI actions ARB_CONFIG/ARB_ASSIGN/ARB_STUDY_CONFIG/ARB_RUN share the existing
operationBody protocol. The study engines are ARB_KINEMATICS, ARB_MECHANICAL,
ARB_SIZING. Plan motion is PRESCRIBED with an explicit N×2 wheelTravel_m, or
ROLL with native rollAngles_rad and axleHeave_m. A geometric study also supplies
two strictly ordered driverTravel_m paths of at least three samples. They are
sampling declarations, not an expanded Cartesian product. ROLL calls the existing
axle-roll solver and retains its returned wheel coordinates/failures. It does not
provide a general combined steering/bump/roll solver.

Optional plan.packaging is a canonical AntiRollBarPackagingDefinition. SIZING
instead uses plan.target={stiffness_Nm_per_rad,sourceKind,sourceNote} with no
motion or solver options. Empty/partial plans remain persistible and editable.
GLOBAL_STATIC selects inputs.arbAxles FRONT/REAR (unique ordered column); its
exact registered assignments are resolved during preparation. Absent selection
means no bar even if the library contains resources.

Exact worker reception reconstructs the requested operation, project/revision,
scenario, bar revision, axis, adjustment, parameters/provenance, parents, ordered
grids, motion/options and result type. Payload validation rebuilds sampled
algebra/energy from validated stored parents, without rerunning forward BUMP.
Native BUMP/ROLL payloads do not store historical solver options; those requested
options belong to the complete immutable prepared execution context. This is
semantic/model validation, not cryptographic proof of an execution history.
RF01–03, epochs, cancellation, atomic project/session acceptance and existing
graph storage apply unchanged. A mathematically valid other revision is rejected
even if its physical dependencies are reusable.

Physical reuse separately projects consumed structure, never output equality:

| Change | Expected compatibility |
|---|---|
| consumed stiffness / free reference / geometry / adjustment | dependent mechanics/global STALE |
| stiffness only | pure ARB kinematics reusable |
| G/diameters stored under independent known stiffness | known-law mechanics reusable |
| G/diameter/length used by circular law | mechanics/global STALE |
| front ARB / unrelated tire force family | independent rear BUMP / ARB respectively reusable |
| ordered sampling / branch-affecting inputs / options | dependent study STALE |
| support centres unused by mechanics | mechanics reusable; packaging consuming them STALE |

Reused evidence retains its old execution/version. Registered revisions and
historical ledgers cannot be overwritten. Optional ARB registries are not added
on loading authentic MAT0.19–0.22. New active physical schemas are0.23; logical
project/scenario/envelope formats remain the existing contracts. No provider
toolbox object is necessary for ARB, worker transport or MAT roundtrip.

## Packaging and Desktop workflow

The bounded packaging definition declares component CAPSULE/SPHERE with point
aliases (axis stations, arm tips, drivers, support centres), radii, provenance,
fixed occupied native obstacles and selected clearance pairs. Axis stations are
computed from arm points; support centres/material radii are never inferred.
Unknown support centres remain NaN point availability; unknown radii/clearance
stay []. Native distance kernels are reused. A result is nominal or sampled,
with source, resolved volumes, check statuses and required/evaluated coverage.
CLEAR_SAMPLED applies only to evaluated selected checks. It is not continuous
clearance, CAD, support-force analysis or fabrication certification.

Desktop: select ARB → Definition, enter ID/axis/representation; on Parameters
enter physical values and sources, then Apply ARB revision. The dedicated table
avoids nested scrolling and shares the same definition draft. Blank parameters stay unknown. The explicit
synthetic draft button is a software example only. On Study select engine/motion,
enter paired mm samples (or native ROLL degrees/heave), geometric driver paths,
or the shaft target/source. On Packaging optionally define occupied components,
obstacles and pairs. Apply study reports readiness. Run uses the existing explicit
sync/process policy. Results selects evidence/reference and quantity, displays
stored numbers/curves and simplified centre lines; modal rates require explicit
path derivatives and secants a matching reference/increment. Assign exact ID@revision
per axle; Global static selects active axles, runs and compares historical evidence.
Save/Load uses the project MAT workflow. Separate drafts cannot be lost by another
Apply, and Run/Save are blocked until relevant drafts are applied.

## Alternatives, limitations and validation

The chosen scalar closure is the historical analytic circle/sphere arithmetic,
shared without changing its classifications. A second suspension solver was
discarded as redundant. Interpolating force, torque and rate independently was
discarded because it can violate virtual work. Interpolating only arm angle was
discarded because it can violate link length against the interpolated driver.
Automatically inferring zero preload, material, support radii or target stiffness
was discarded because missing data does not justify those assumptions. No hidden
direct-roll spring is added to a geometric energy already derived from wheel motion.
These are decisions of the authorized0.23 development, not reconstructed historical
motivations. Unknown older motivations remain pending reconstruction.

Independent tests use equivalent quadratic energy, circular section laws, a
separate planar trigonometric link solution, finite differences of that independent
energy, virtual work/link moments, reflection/axis reversal and ideal coupled
global systems. Native integration tests additionally exercise actual BUMP/ROCKER/
ROLL sources. Test tolerances document arithmetic/differentiation error; historical
solver budgets are not relaxed. Developer verification does not claim an independent
audit or experimental validation. The version report records actual executed tests,
initial failures/corrections, omitted suites, Desktop/worker/MAT evidence and costs.

Scope excludes flexible/bent/noncoaxial bars, calculated blades, compliant supports,
stress/buckling/fatigue/hydraulics/FEA/manufacturing, dynamic tire/contact models,
automatic optimal ARB targets, joint INTEGRATED synthesis and v0.24 performance.
