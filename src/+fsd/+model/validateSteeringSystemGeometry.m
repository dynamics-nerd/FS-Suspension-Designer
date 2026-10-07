function isValid = validateSteeringSystemGeometry(steering)
%VALIDATESTEERINGSYSTEMGEOMETRY Validate canonical v0.5 steering geometry.

if ~isstruct(steering) || ~isscalar(steering)
    invalid("SteeringSystemGeometry must be a scalar struct.");
end
required = ["schemaVersion", "kind", "frontAxleGeometry", ...
    "rackGeometry", "rearAxleX_m", "identity"];
if ~all(isfield(steering, required)) || ...
        string(steering.schemaVersion) ~= "0.5.0" || ...
        string(steering.kind) ~= "SteeringSystemGeometry"
    invalid("Unsupported or incomplete SteeringSystemGeometry schema.");
end
try
    fsd.model.validateAxleGeometry(steering.frontAxleGeometry);
catch cause
    exception = MException("fsd:model:InvalidSteeringSystemGeometry", ...
        "The steering model contains an invalid front axle.");
    exception = addCause(exception, cause);
    throwAsCaller(exception);
end
if string(steering.frontAxleGeometry.axleId) ~= "FRONT"
    error("fsd:model:SteeringRequiresFrontAxle", ...
        "SteeringSystemGeometry requires a FRONT axle.");
end
expected = fsd.model.steeringSystemIdentity(steering);
try
    fsd.model.validateSteeringSystemIdentity(steering.identity);
catch cause
    exception = MException("fsd:model:InvalidSteeringSystemGeometry", ...
        "The steering model contains an invalid identity.");
    exception = addCause(exception, cause);
    throwAsCaller(exception);
end
if ~isequal(steering.identity, expected)
    invalid("Steering identity does not match the model fields.");
end
rack = steering.rackGeometry;
axisVector_m = rack.rightInnerStatic_m - rack.leftInnerStatic_m;
expectedSeparation_m = norm(axisVector_m);
expectedAxis = axisVector_m ./ expectedSeparation_m;
tolerances = fsd.model.numericTolerances();
tolerance = 10 * (tolerances.AbsTol_m + ...
    tolerances.RelTol * max(expectedSeparation_m, 1));
if abs(rack.jointSeparation_m - expectedSeparation_m) > tolerance || ...
        max(abs(rack.axisDirection - expectedAxis)) > tolerance || ...
        ~isequal(rack.leftInnerStatic_m, ...
        fsd.model.getPoint(steering.frontAxleGeometry.leftGeometry, ...
        "FL_TIE_ROD_INBOARD")) || ...
        ~isequal(rack.rightInnerStatic_m, ...
        fsd.model.getPoint(steering.frontAxleGeometry.rightGeometry, ...
        "FR_TIE_ROD_INBOARD"))
    invalid("rackGeometry contradicts the front axle hardpoints.");
end
isValid = true;
end

function invalid(message)
error("fsd:model:InvalidSteeringSystemGeometry", message);
end
