function assertGeometryIdentity(geometry, identity)
%ASSERTGEOMETRYIDENTITY Reject results produced by another geometry.

expectedIdentity = fsd.model.geometryIdentity(geometry);
if ~isequal(expectedIdentity, identity)
    error("fsd:analysis:GeometryMismatch", ...
        "The kinematic result was produced by a different geometry.");
end
end
