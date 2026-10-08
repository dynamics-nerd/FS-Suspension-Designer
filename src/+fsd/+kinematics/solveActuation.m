function result = solveActuation(actuation, kinematicResult, options)
%SOLVEACTUATION Solve one downstream rod/rocker/damper state analytically.

if nargin < 3
    options = struct();
end
fsd.model.validateActuationGeometry(actuation);
validateActuationSource(kinematicResult);
if ~isequal(kinematicResult.geometryIdentity, ...
        actuation.cornerGeometryIdentity) || ...
        string(kinematicResult.geometryIdentity.cornerId) ~= ...
        string(actuation.cornerId)
    error("fsd:kinematics:ActuationGeometryMismatch", ...
        "Source result belongs to another corner geometry.");
end
referenceAngle_rad = parseReferenceAngle(options);
result = solveActuationCore(actuation, kinematicResult, referenceAngle_rad);
fsd.kinematics.validateActuationResult(result, actuation);
end

function angle_rad = parseReferenceAngle(options)
if ~isstruct(options) || ~isscalar(options)
    error("fsd:kinematics:InvalidActuationOptions", ...
        "options must be a scalar struct.");
end
allowed = "ReferenceRockerAngle_rad";
names = string(fieldnames(options));
if any(~ismember(names, allowed))
    error("fsd:kinematics:InvalidActuationOptions", ...
        "Unknown actuation solver option.");
end
angle_rad = 0;
if isfield(options, "ReferenceRockerAngle_rad")
    angle_rad = options.ReferenceRockerAngle_rad;
    if ~isnumeric(angle_rad) || ~isreal(angle_rad) || ...
            ~isscalar(angle_rad) || ~isfinite(angle_rad)
        error("fsd:kinematics:InvalidActuationOptions", ...
            "ReferenceRockerAngle_rad must be a finite real scalar.");
    end
    angle_rad = double(angle_rad);
end
end
