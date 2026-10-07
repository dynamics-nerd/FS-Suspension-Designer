function result = solveAxleRoll(axle, bodyRollAngle, axleHeave, ...
    angleUnit, lengthUnit, options)
%SOLVEAXLEROLL Solve axle travel compatible with a flat rolled road.

if nargin < 6
    options = struct();
end
fsd.model.validateAxleGeometry(axle);
phi_rad = fsd.model.convertAngleToRadians(bodyRollAngle, angleUnit);
heave_m = fsd.model.convertLengthToMetres(axleHeave, lengthUnit);
if ~isscalar(phi_rad) || ~isscalar(heave_m)
    error("fsd:kinematics:InvalidAxleRollTarget", ...
        "Body roll angle and axle heave must be finite real scalars.");
end
fsd.geometry.bodyRollRoadFrame(phi_rad);
settings = fsd.kinematics.rollSolverSettings(options);
timer = tic;
results = solveAxleRollPath(axle, phi_rad, heave_m, settings);
result = results(1);
result.elapsedTime_s = toc(timer);
fsd.kinematics.validateAxleRollResult(result);
end
