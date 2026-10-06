function isValid = validateAxleIdentity(identity)
%VALIDATEAXLEIDENTITY Validate a canonical v0.4 axle identity.

if ~isstruct(identity) || ~isscalar(identity)
    invalid("Axle identity must be a scalar struct.");
end
required = ["schemaVersion", "kind", "axleSchemaVersion", "axleId", ...
    "leftGeometryIdentity", "rightGeometryIdentity"];
for index = 1:numel(required)
    if ~isfield(identity, required(index))
        invalid("Axle identity is missing field '%s'.", required(index));
    end
end
if ~isTextScalar(identity.schemaVersion) || ...
        string(identity.schemaVersion) ~= "1.0.0" || ...
        ~isTextScalar(identity.kind) || ...
        string(identity.kind) ~= "AxleGeometryIdentity" || ...
        ~isTextScalar(identity.axleSchemaVersion) || ...
        string(identity.axleSchemaVersion) ~= "0.4.0" || ...
        ~isTextScalar(identity.axleId) || ...
        ~ismember(string(identity.axleId), ["FRONT", "REAR"])
    invalid("Unsupported or invalid axle identity schema.");
end
try
    fsd.model.validateGeometryIdentity(identity.leftGeometryIdentity);
    fsd.model.validateGeometryIdentity(identity.rightGeometryIdentity);
catch cause
    exception = MException("fsd:model:InvalidAxleIdentity", ...
        "Axle identity contains an invalid corner identity.");
    exception = addCause(exception, cause);
    throwAsCaller(exception);
end
axleId = string(identity.axleId);
leftCorner = string(identity.leftGeometryIdentity.cornerId);
rightCorner = string(identity.rightGeometryIdentity.cornerId);
if (axleId == "FRONT" && ...
        (leftCorner ~= "FL" || rightCorner ~= "FR")) || ...
        (axleId == "REAR" && ...
        (leftCorner ~= "RL" || rightCorner ~= "RR"))
    invalid("Axle identity corners contradict axleId or left/right order.");
end
isValid = true;
end

function tf = isTextScalar(value)
tf = (ischar(value) && isrow(value)) || ...
    (isstring(value) && isscalar(value) && ~ismissing(value));
end

function invalid(message, varargin)
error("fsd:model:InvalidAxleIdentity", message, varargin{:});
end
