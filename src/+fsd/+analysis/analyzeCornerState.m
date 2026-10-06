function analysis = analyzeCornerState(geometry, result)
%ANALYZECORNERSTATE Derive single-corner metrics from one solver result.

validateGeometry(geometry);
analysis = analyzeCornerStateCore(geometry, result);
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
