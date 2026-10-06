function contact = geometricWheelContact(geometry, result)
%GEOMETRICWHEELCONTACT Derive and apply the v0.4 rigid-wheel contact model.

fsd.model.validateDoubleWishboneGeometry(geometry);
radius_m = wheelContactRadius(geometry);
if nargin < 2 || isempty(result)
    result = [];
else
    validateResult(geometry, result);
    if ~result.converged
        error("fsd:analysis:KinematicsNotConverged", ...
            "A converged corner result is required for dynamic contact.");
    end
end
contact = geometricWheelContactCore(geometry, result, radius_m);
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
