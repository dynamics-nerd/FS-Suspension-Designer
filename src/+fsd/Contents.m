% FS Suspension Designer engineering core.
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
%   fsd.packaging    - Future clearance and envelope checks.
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
