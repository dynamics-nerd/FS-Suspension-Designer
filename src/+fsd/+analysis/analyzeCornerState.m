function analysis = analyzeCornerState(geometry, result)
%ANALYZECORNERSTATE Derive single-corner metrics from one solver result.

validateGeometry(geometry);
validateResult(result);
assertGeometryIdentity(geometry, result.geometryIdentity);
analysis = analyzeCornerStateCore(geometry, result);
end

function validateResult(result)
try
    fsd.kinematics.validateKinematicResult(result);
catch cause
    exception = MException("fsd:analysis:InvalidKinematicResult", ...
        "result must satisfy the complete KinematicResult contract.");
    exception = addCause(exception, cause);
    throwAsCaller(exception);
end
end

function validateGeometry(geometry)
try
    fsd.model.validateDoubleWishboneGeometry(geometry);
catch cause
    exception = MException("fsd:analysis:InvalidGeometry", ...
        "geometry must be a valid DoubleWishboneGeometry.");
    exception = addCause(exception, cause);
    throwAsCaller(exception);
end
end
