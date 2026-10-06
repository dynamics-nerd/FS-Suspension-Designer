function analysis = analyzeAxleState(axle, axleResult)
%ANALYZEAXLESTATE Compute FVICs, ideal contacts and axle roll center.

fsd.model.validateAxleGeometry(axle);
leftRadius_m = wheelContactRadius(axle.leftGeometry);
rightRadius_m = wheelContactRadius(axle.rightGeometry);
if nargin < 2 || isempty(axleResult)
    leftResult = [];
    rightResult = [];
    requestedWheelTravel_m = 0;
else
    validateAxleResult(axle, axleResult);
    if ~axleResult.converged
        error("fsd:analysis:AxleKinematicsNotConverged", ...
            "Both corner results must converge before roll-center analysis.");
    end
    leftResult = axleResult.leftResult;
    rightResult = axleResult.rightResult;
    requestedWheelTravel_m = double( ...
        axleResult.requestedWheelTravel_m);
end
analysis = analyzeAxleStateCore(axle, leftResult, rightResult, ...
    requestedWheelTravel_m, leftRadius_m, rightRadius_m, ...
    fsd.model.axleIdentity(axle));
end

function validateAxleResult(axle, result)
try
    fsd.kinematics.validateAxleKinematicResult(result);
catch cause
    exception = MException("fsd:analysis:InvalidAxleKinematicResult", ...
        "axleResult violates the AxleKinematicResult contract.");
    exception = addCause(exception, cause);
    throwAsCaller(exception);
end
if ~isequal(fsd.model.axleIdentity(axle), result.axleIdentity)
    error("fsd:analysis:AxleGeometryMismatch", ...
        "The axle result belongs to a different axle geometry.");
end
end
