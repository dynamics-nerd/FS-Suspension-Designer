% FS Suspension Designer engineering core.
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
