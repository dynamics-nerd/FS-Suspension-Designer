function result = solveAxleTravel(axle, wheelTravel, inputUnit, options)
%SOLVEAXLETRAVEL Solve prescribed [left,right] wheel travel for one axle.

if nargin < 4
    options = struct();
end
fsd.model.validateAxleGeometry(axle);
requested_m = fsd.model.convertLengthToMetres(wheelTravel, inputUnit);
if ~isvector(requested_m) || numel(requested_m) ~= 2
    error("fsd:kinematics:InvalidWheelTravel", ...
        "Axle wheelTravel must contain exactly [left,right].");
end
requested_m = reshape(double(requested_m), 1, 2);
settings = fsd.kinematics.solverSettings(options);
result = solveAxleTravelCore(axle, requested_m, settings);
fsd.kinematics.validateAxleTravelResult(result);
end
