function sweep = solveBumpSweep(geometry, wheelTravel, inputUnit, options)
%SOLVEBUMPSWEEP Solve ordered targets using continuation between results.

if nargin < 4
    options = struct();
end
fsd.model.validateDoubleWishboneGeometry(geometry);
wheelTravel_m = fsd.model.convertLengthToMetres(wheelTravel, inputUnit);
if ~isvector(wheelTravel_m) || isempty(wheelTravel_m)
    error("fsd:kinematics:InvalidWheelTravel", ...
        "wheelTravel must be a nonempty finite real vector.");
end
wheelTravel_m = wheelTravel_m(:);
settings = fsd.kinematics.solverSettings(options);

timer = tic;
results = solveBumpPath(geometry, wheelTravel_m, settings);
elapsed_s = toc(timer);
converged = reshape([results.converged], [], 1);
camber_rad = reshape([results.camber_rad], [], 1);
achievedWheelTravel_m = reshape([results.achievedWheelTravel_m], [], 1);

sweep = struct( ...
    "schemaVersion", "0.2.0", ...
    "kind", "BumpSweepResult", ...
    "requestedWheelTravel_m", wheelTravel_m, ...
    "achievedWheelTravel_m", achievedWheelTravel_m, ...
    "camber_rad", camber_rad, ...
    "converged", converged, ...
    "allConverged", all(converged), ...
    "elapsedTime_s", elapsed_s, ...
    "results", results);
end

