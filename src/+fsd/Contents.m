% FS Suspension Designer engineering core.
%
% v0.19 Packaging & Physical Feasibility
%   fsd.packaging.createVolume          - Explicit SI solid/free-region declaration.
%   fsd.packaging.createDefinition      - Required pairs, margins, local exemptions, regions.
%   fsd.packaging.distance              - Exact supported finite-primitive separation.
%   fsd.packaging.segmentDistance       - Closed-segment independent geometric kernel.
%   fsd.packaging.resolveVolumes        - Native stored pose/endpoint bindings, no solves.
%   fsd.packaging.evaluate              - Nominal or supplied BUMP sampled evidence.
%   fsd.packaging.validateVolume        - Canonical volume reconstruction.
%   fsd.packaging.validateDefinition    - Canonical declaration reconstruction.
%   fsd.packaging.validateResult        - Algebraic evidence replay, no forward solve.
%   fsd.packaging.plotResult            - Actual declared solids/stored sample/witnesses.
%   fsd.project.createPackagingScenario - Native project scenario with explicit parent.
%   fsd.project.createPackagingSource   - Verified bounded dependency projection, not execution.
%   fsd.project.validatePackagingSource - Native source/context integrity without forward solves.
%   fsd.project.resultCompatibilities   - Canonical classification of a validated ledger.
%   fsd.project.mergeEngineeringProjectHistory - Validated immutable worker-delta union.
%   fsd.project.encodeStorageGraph      - Lossless plain-value transport/storage DAG.
%   fsd.project.decodeStorageGraph      - Checked backward-reference DAG reconstruction.
%
% v0.17 Concept-to-Seed & Parametric Suspension Geometry
%   fsd.construction.seedParameterCatalog           - Required decisions, no physical defaults.
%   fsd.construction.createSeedParameter            - Native units/roles for a catalogued decision.
%   fsd.construction.createParametricSeedDefinition  - Progressive corner or explicit FRONT family.
%   fsd.construction.validateParametricSeedDefinition - Canonical input record reconstruction.
%   fsd.construction.seedReferenceIds               - Only consumed vehicle dimensions.
%   fsd.construction.parametricSeedReadiness         - Missing inputs, no build/solves.
%   fsd.construction.buildParametricSeed             - Deterministic native geometry/derivations.
%   fsd.construction.validateParametricSeedResult     - Rebuild nominal evidence, no solves.
%   fsd.construction.checkConceptGeometryConsistency - Nominal dimensions/frame/wheel datum.
%   fsd.project.checkConceptGeometryConsistency      - Physical concept gate before comparison.
%   fsd.project.checkParametricSeedBump               - Explicit native sampled verification.
%   fsd.project.validateParametricSeedBump            - Stored source/plan/quality replay.
%   fsd.project.createSeedSteering                    - Optional explicit native steering adapter.
%   fsd.project.registerParametricSeed                - Atomic adoption with historical origin.
%   fsd.synthesis.validateNominalSeed                 - Pure existing builder checks, no search.
%   fsd.synthesis.bumpSweepQuality                    - Existing local closure guard, no solve.
%
% v0.16 Vehicle Concept & Engineering Project Workflow
%   fsd.project.conceptParameterCatalog             - Concept quantities, not performance targets.
%   fsd.project.createConceptParameter              - Native parameter plus origin and confirmation.
%   fsd.project.validateConceptParameter            - Canonical quantity/provenance reconstruction.
%   fsd.project.createVehicleConcept                - Progressive, optional vehicle data.
%   fsd.project.validateVehicleConcept              - Concept definition and identity integrity.
%   fsd.project.deriveVehicleConcept                - Explicit native v0.9 conditioned derivations.
%   fsd.project.validateConceptDerivation            - Original inputs and algebraic evidence.
%   fsd.project.selectConceptValues                 - Explicit interval samples, not robustness.
%   fsd.project.createEngineeringScenario            - Explicit action/spec/plan/control intent.
%   fsd.project.validateEngineeringScenario          - Canonical scenario identity.
%   fsd.project.createEngineeringProject             - Optional resources/scenarios, historical ledger.
%   fsd.project.validateEngineeringProject           - Complete configuration and evidence integrity.
%   fsd.project.reviseEngineeringProject             - Immutable engineering configuration revisions.
%   fsd.project.specificationSources                 - Authoritative native target/source catalogue.
%   fsd.project.designReadiness                      - Actionable preparation without solves/searches.
%   fsd.project.prepareEngineeringScenario           - Public native input adapters, no execution.
%   fsd.project.runEngineeringScenario               - Native execution; optional validated append output.
%   fsd.project.validateEngineeringResult            - Original snapshot and native payload reconstruction.
%   fsd.project.resultCompatibility                  - Current/reusable/stale/incompatible dependencies.
%   fsd.project.attachEngineeringResult              - Associate original evidence without revision change.
%   fsd.project.saveEngineeringProject               - Validated versioned MAT, explicit overwrite.
%   fsd.project.loadEngineeringProject               - Trusted MAT integrity; no hidden forward solves.
%   fsd.synthesis.searchSettings                     - Pure existing controller option normalizer.
%
% v0.15 Actuation Geometry & Motion Ratio Synthesis
%   fsd.model.actuationDesignPointRoles             - Four native points and canonical axis-line point.
%   fsd.model.getActuationDesignPoint               - Closed nominal global-coordinate lookup.
%   fsd.synthesis.createActuationDesignSpace         - Fixed corner, actuation/mechanical seeds and full spec.
%   fsd.synthesis.validateActuationDesignSpace       - Reconstruct bindings, bounds and independent axis DOFs.
%   fsd.synthesis.normalizeActuationVariables        - SI to shared normalized box.
%   fsd.synthesis.denormalizeActuationVariables      - Shared finite/frozen coordinate contract.
%   fsd.synthesis.buildActuationCandidate            - Native factories, links, rocker and coilover association.
%   fsd.synthesis.evaluateActuationCandidate         - Fresh BUMP/actuation, native mechanical analysis, assessment.
%   fsd.synthesis.runActuationInverseSearch          - Unchanged boundedDirectSearch, local immutable cache.
%   fsd.synthesis.validateActuationSynthesisEvaluation - Evidence/quality/context replay without forward solves.
%   fsd.synthesis.validateActuationSynthesisResult    - Complete controller/cache/counter/selection replay.
%   fsd.synthesis.compareActuationSynthesisCandidates - Full native assessments and physical changes.
%   fsd.synthesis.plotActuationSynthesisResult        - Stored curves/gaps, targets, history and native geometry.
%
% v0.14 Steering Geometry & Ackermann Synthesis
%   fsd.synthesis.createSteeringDesignSpace           - Coherent FRONT corners and native rack seed.
%   fsd.synthesis.validateSteeringDesignSpace         - Reconstruct authorized joint definition.
%   fsd.synthesis.normalizeSteeringVariables         - Independent SI coordinates to unit box.
%   fsd.synthesis.denormalizeSteeringVariables       - Shared coordinate/frozen contract.
%   fsd.synthesis.buildSteeringCandidate             - Both corners, rack and derived tie lengths.
%   fsd.synthesis.evaluateSteeringCandidate          - Fresh bilateral BUMP/RACK and optional ROLL.
%   fsd.synthesis.runSteeringInverseSearch           - Shared boundedDirectSearch controller.
%   fsd.synthesis.validateSteeringSynthesisEvaluation - Native evidence/assessment, no solves.
%   fsd.synthesis.validateSteeringSynthesisResult     - Joint snapshots/cache/controller replay.
%   fsd.synthesis.compareSteeringSynthesisCandidates  - Native joint comparisons and physical changes.
%   fsd.synthesis.plotSteeringSynthesisResult         - Curves/gaps, trace, geometry and changed coordinates.
%
% v0.13 Axle-Level Suspension Synthesis
%   fsd.synthesis.createAxleDesignSpace          - Explicit FL/FR or RL/RR seeds and plans.
%   fsd.synthesis.validateAxleDesignSpace        - Bounds, FIXED and selected symmetry links.
%   fsd.synthesis.normalizeAxleVariables         - Independent SI coordinates to unit box.
%   fsd.synthesis.denormalizeAxleVariables       - Shared v0.12 coordinate contract.
%   fsd.synthesis.buildAxleCandidate             - Rebuild both corners deterministically.
%   fsd.synthesis.evaluateAxleCandidate          - Fresh bilateral BUMP and optional ROLL.
%   fsd.synthesis.runAxleInverseSearch           - One joint objective and shared controller.
%   fsd.synthesis.validateAxleSynthesisEvaluation - Native evidence reconstruction, no solves.
%   fsd.synthesis.validateAxleSynthesisResult     - Joint provenance and deterministic replay.
%   fsd.synthesis.compareAxleSynthesisCandidates  - Joint targets and changes/tradeoffs.
%   fsd.synthesis.plotAxleSynthesisResult         - Both geometries, targets, trace and failures.
%
% v0.12 Inverse Suspension Synthesis
%   fsd.synthesis.createDesignSpace             - Immutable seed/v0.11 bounded bindings.
%   fsd.synthesis.validateDesignSpace           - Reconstruct supported definition.
%   fsd.synthesis.normalizeVariables            - SI to normalized closed box.
%   fsd.synthesis.denormalizeVariables          - Normalized coordinates to SI.
%   fsd.synthesis.buildCandidateGeometry        - Authorized inboard coordinate mutation.
%   fsd.synthesis.evaluateSynthesisCandidate    - Explicit fresh BUMP orchestration.
%   fsd.synthesis.boundedDirectSearch           - Deterministic mathematical poll controller.
%   fsd.synthesis.runInverseSearch              - Traceable physical candidate set.
%   fsd.synthesis.validateSynthesisEvaluation   - Native evidence and quality, no solves.
%   fsd.synthesis.validateSynthesisResult       - Evidence validation and controller replay.
%   fsd.synthesis.compareSynthesisCandidates    - v0.11 comparison plus HP changes.
%   fsd.synthesis.plotSynthesisResult           - Trace, variables and native target curves.
%
% v0.11 Design Requirements, Targets & Evaluation
%   fsd.model.createDesignParameter             - Role, availability, provenance.
%   fsd.model.createDesignTarget                - Explicit scalar/band/curve target.
%   fsd.model.createSuspensionDesignTargets     - Standalone target collection.
%   fsd.model.createDesignConstraint            - Fixed hardpoint or XYZ box.
%   fsd.model.createDesignSpecification         - Progressive specification.
%   fsd.model.createDesignCandidate             - Native model/result sources.
%   fsd.model.designMetricCatalog               - Typed supported result metrics.
%   fsd.model.designScope                       - Vehicle/axle/corner/component/point.
%   fsd.model.convertDesignUnits                - Explicit SI boundary conversion.
%   fsd.model.designVariableSpace               - Bounds/bindings, no optimizer.
%   fsd.model.mirrorBumpDesignTarget            - Explicit limited symmetry rule.
%   fsd.analysis.evaluateDesignCandidate        - Validated sampled comparisons.
%   fsd.analysis.validateDesignCandidate        - Reconstruct native source integrity.
%   fsd.analysis.validateDesignAssessment       - Reconstruct errors/status/coverage.
%   fsd.analysis.designReadiness                - Missing input/result diagnostics.
%   fsd.analysis.compareDesignCandidates        - Same specification, no winner.
%   fsd.analysis.designAssessmentTable          - Requirement dashboard with units.
%   fsd.analysis.plotDesignTargetEvaluation     - Targets/results/errors/gaps.
%
% v0.10 Coupled Chassis Pose & Global Static Equilibrium
%   fsd.model.createVerticalTireModel               - Explicit vertical-only tire.
%   fsd.model.createGlobalStaticSystem              - Four-corner source aggregate.
%   fsd.analysis.prepareGlobalStaticSystem          - Validate and segment sampled paths.
%   fsd.analysis.evaluateGlobalStaticState          - Prescribed seven-coordinate energy.
%   fsd.analysis.solveGlobalStaticEquilibrium       - Scaled bounded Newton/multistart.
%   fsd.analysis.validateGlobalStaticState          - Reconstruct evaluated physics.
%   fsd.analysis.validateGlobalStaticEquilibrium    - Reconstruct roots/stability/selection.
%   fsd.analysis.plotGlobalStaticEquilibrium        - Pose, loads, energy slices.
%   fsd.analysis.benchmarkGlobalStaticEquilibrium   - Separate preparation/core timings.
%
% v0.9 Vehicle Parameters, Static Loads & Corner Equilibrium
%   fsd.model.createVehicleParameters          - Standalone SI mass/CG contract.
%   fsd.model.createVehicleLoadCase            - Explicit load distribution mode.
%   fsd.analysis.analyzeStaticVehicleLoads     - Reactions/family and local support.
%   fsd.analysis.solveCornerStaticEquilibrium  - Validated sampled-path roots.
%   fsd.analysis.compareStaticVehicleCases     - Explicit scenario differences.
%   fsd.analysis.plotStaticVehicleLoads        - Contacts and known reactions.
%   fsd.analysis.plotCornerStaticEquilibrium   - Force path and local roots.
%
% Namespaces
%   fsd.model        - Canonical data contracts and validation.
%   fsd.geometry     - Geometry primitives and static geometry operations.
%   fsd.kinematics   - Suspension and geometric actuation kinematics.
%   fsd.analysis     - Suspension, steering, actuation and coilover response.
%   fsd.vehicle      - Future whole-vehicle composition.
%   fsd.tire         - Future replaceable tire-model contracts.
%   fsd.dynamics     - Future vehicle-dynamics calculations.
%   fsd.packaging    - Explicit primitive clearance and sampled envelope checks.
%   fsd.rules        - Future rules evaluation, independent of kinematics.
%   fsd.optimization - Future optimization orchestration.
%   fsd.export       - Future external-format adapters.
%
% v0.8 Spring, Damper & Wheel-Rate Modelling
%   fsd.model.createSpringDamperModel          - Optional SI coilover contract.
%   fsd.model.convertMechanicalUnits          - Explicit mechanical units.
%   fsd.analysis.analyzeSpringDamperState      - Axial-only single-state response.
%   fsd.analysis.analyzeSpringDamperSweep      - Signed wheel forces and tangent rate.
%   fsd.analysis.analyzePrescribedSpringDamperPath - Explicit 1-D benchmark path.
%   fsd.analysis.plotSpringDamperSweep         - Nine curves and provided limits.
