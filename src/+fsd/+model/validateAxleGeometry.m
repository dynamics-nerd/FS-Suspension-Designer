function isValid = validateAxleGeometry(axle)
%VALIDATEAXLEGEOMETRY Validate a canonical v0.4 axle geometry.

if ~isstruct(axle) || ~isscalar(axle)
    invalid("AxleGeometry must be a scalar struct.");
end
required = ["schemaVersion", "kind", "axleId", ...
    "leftGeometry", "rightGeometry"];
for index = 1:numel(required)
    if ~isfield(axle, required(index))
        invalid("AxleGeometry is missing field '%s'.", required(index));
    end
end
if ~isTextScalar(axle.schemaVersion) || ...
        string(axle.schemaVersion) ~= "0.4.0" || ...
        ~isTextScalar(axle.kind) || string(axle.kind) ~= "AxleGeometry" || ...
        ~isTextScalar(axle.axleId) || ...
        ~ismember(string(axle.axleId), ["FRONT", "REAR"])
    invalid("Unsupported or invalid AxleGeometry schema.");
end

try
    fsd.model.validateDoubleWishboneGeometry(axle.leftGeometry);
    fsd.model.validateDoubleWishboneGeometry(axle.rightGeometry);
catch cause
    exception = MException("fsd:model:InvalidAxleGeometry", ...
        "AxleGeometry contains an invalid corner geometry.");
    exception = addCause(exception, cause);
    throwAsCaller(exception);
end

axleId = string(axle.axleId);
leftCorner = string(axle.leftGeometry.cornerId);
rightCorner = string(axle.rightGeometry.cornerId);
expectedCorners = ["FL", "FR"];
if axleId == "REAR"
    expectedCorners = ["RL", "RR"];
end
if leftCorner ~= expectedCorners(1) || rightCorner ~= expectedCorners(2)
    invalid("AxleGeometry corners contradict axleId or left/right order.");
end
if string(axle.leftGeometry.referenceFrame.id) ~= ...
        string(axle.rightGeometry.referenceFrame.id) || ...
        string(axle.leftGeometry.referenceFrame.axisConvention) ~= ...
        string(axle.rightGeometry.referenceFrame.axisConvention) || ...
        string(axle.leftGeometry.metadata.coordinateSystem) ~= ...
        string(axle.rightGeometry.metadata.coordinateSystem) || ...
        string(axle.leftGeometry.schemaVersion) ~= ...
        string(axle.rightGeometry.schemaVersion)
    invalid("Both corners must use the same compatible reference contract.");
end
isValid = true;
end

function tf = isTextScalar(value)
tf = (ischar(value) && isrow(value)) || ...
    (isstring(value) && isscalar(value) && ~ismissing(value));
end

function invalid(message, varargin)
error("fsd:model:InvalidAxleGeometry", message, varargin{:});
end
