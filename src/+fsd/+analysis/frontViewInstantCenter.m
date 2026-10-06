function instantCenter = frontViewInstantCenter(geometry, result)
%FRONTVIEWINSTANTCENTER Compute one corner kinematic FVIC in global YZ.

fsd.model.validateDoubleWishboneGeometry(geometry);
if nargin < 2 || isempty(result)
    result = [];
else
    validateResult(geometry, result);
    if ~result.converged
        error("fsd:analysis:KinematicsNotConverged", ...
            "A converged corner result is required for dynamic FVIC.");
    end
end
instantCenter = frontViewInstantCenterCore(geometry, result);
end

function validateResult(geometry, result)
try
    fsd.kinematics.validateKinematicResult(result);
catch cause
    exception = MException("fsd:analysis:InvalidKinematicResult", ...
        "result must satisfy the complete KinematicResult contract.");
    exception = addCause(exception, cause);
    throwAsCaller(exception);
end
if ~isequal(fsd.model.geometryIdentity(geometry), ...
        result.geometryIdentity)
    error("fsd:analysis:GeometryMismatch", ...
        "The corner result belongs to a different geometry.");
end
end
