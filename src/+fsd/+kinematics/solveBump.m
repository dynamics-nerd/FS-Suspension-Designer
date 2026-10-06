function result = solveBump(geometry, wheelTravel, inputUnit, options)
%SOLVEBUMP Solve one bump/rebound target on the static-connected branch.

if nargin < 4
    options = struct();
end
fsd.model.validateDoubleWishboneGeometry(geometry);
wheelTravel_m = fsd.model.convertLengthToMetres(wheelTravel, inputUnit);
if ~isscalar(wheelTravel_m)
    error("fsd:kinematics:InvalidWheelTravel", ...
        "wheelTravel must be a finite real scalar.");
end
settings = fsd.kinematics.solverSettings(options);
results = solveBumpPath(geometry, wheelTravel_m, settings);
result = results(1);
end

