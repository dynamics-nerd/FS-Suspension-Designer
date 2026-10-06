function isValid = validateGeometryIdentity(identity)
%VALIDATEGEOMETRYIDENTITY Validate a canonical solver geometry identity.

if ~isstruct(identity) || ~isscalar(identity)
    error("fsd:model:InvalidGeometryIdentity", ...
        "Geometry identity must be a scalar struct.");
end
required = ["schemaVersion", "kind", "geometrySchemaVersion", ...
    "cornerId", "hardpointIds", "hardpointXyz_m", "wheelAxis"];
for index = 1:numel(required)
    if ~isfield(identity, required(index))
        error("fsd:model:InvalidGeometryIdentity", ...
            "Geometry identity is missing field '%s'.", required(index));
    end
end
if ~isTextScalar(identity.schemaVersion) || ...
        string(identity.schemaVersion) ~= "1.0.0" || ...
        ~isTextScalar(identity.kind) || ...
        string(identity.kind) ~= "DoubleWishboneGeometryIdentity" || ...
        ~isTextScalar(identity.geometrySchemaVersion) || ...
        string(identity.geometrySchemaVersion) ~= "0.2.0"
    error("fsd:model:InvalidGeometryIdentity", ...
        "Unsupported or invalid geometry identity schema.");
end

cornerId = normalizeCorner(identity.cornerId);
expectedIds = cornerId + "_" + fsd.model.requiredHardpointRoles();
if ~isstring(identity.hardpointIds) || ...
        ~isequal(identity.hardpointIds, expectedIds)
    error("fsd:model:InvalidGeometryIdentity", ...
        "Geometry identity hardpoint IDs must use canonical order.");
end
if ~isnumeric(identity.hardpointXyz_m) || ...
        ~isreal(identity.hardpointXyz_m) || ...
        ~isequal(size(identity.hardpointXyz_m), [numel(expectedIds), 3]) || ...
        any(~isfinite(identity.hardpointXyz_m), "all")
    error("fsd:model:InvalidGeometryIdentity", ...
        "Geometry identity coordinates must be finite canonical N-by-3 data.");
end

axis = identity.wheelAxis;
if ~isnumeric(axis) || ~isreal(axis) || ...
        ~isequal(size(axis), [1, 3]) || any(~isfinite(axis))
    error("fsd:model:InvalidGeometryIdentity", ...
        "Geometry identity wheelAxis must be finite and 1-by-3.");
end
tolerances = fsd.model.numericTolerances();
if abs(norm(double(axis), 2) - 1) > ...
        tolerances.AbsTol_m + tolerances.RelTol
    error("fsd:model:InvalidGeometryIdentity", ...
        "Geometry identity wheelAxis must be unit length.");
end
sideSign = 1;
if ismember(cornerId, ["FL", "RL"])
    sideSign = -1;
end
if sideSign * axis(2) <= tolerances.RelTol
    error("fsd:model:InvalidGeometryIdentity", ...
        "Geometry identity wheelAxis must point toward wheel exterior.");
end
isValid = true;
end

function cornerId = normalizeCorner(value)
if ~isTextScalar(value)
    error("fsd:model:InvalidGeometryIdentity", ...
        "Geometry identity cornerId must be a text scalar.");
end
cornerId = upper(strtrim(string(value)));
if ~ismember(cornerId, ["FL", "FR", "RL", "RR"])
    error("fsd:model:InvalidGeometryIdentity", ...
        "Geometry identity cornerId is invalid.");
end
end

function tf = isTextScalar(value)
tf = (ischar(value) && isrow(value)) || ...
    (isstring(value) && isscalar(value) && ~ismissing(value));
end
