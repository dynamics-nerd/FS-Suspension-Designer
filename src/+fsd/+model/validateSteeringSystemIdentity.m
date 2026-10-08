function isValid = validateSteeringSystemIdentity(identity)
%VALIDATESTEERINGSYSTEMIDENTITY Validate the canonical steering identity.

if ~isstruct(identity) || ~isscalar(identity)
    invalid("Steering identity must be a scalar struct.");
end
required = ["schemaVersion", "kind", "steeringSchemaVersion", ...
    "frontAxleIdentity", "leftInnerStatic_m", "rightInnerStatic_m", ...
    "rackAxisDirection", "rearAxleX_m"];
if ~all(isfield(identity, required)) || ...
        string(identity.schemaVersion) ~= "1.0.0" || ...
        string(identity.kind) ~= "SteeringSystemGeometryIdentity" || ...
        string(identity.steeringSchemaVersion) ~= "0.5.0"
    invalid("Unsupported or incomplete steering identity.");
end
try
    fsd.model.validateAxleIdentity(identity.frontAxleIdentity);
catch cause
    exception = MException("fsd:model:InvalidSteeringSystemIdentity", ...
        "The steering identity contains an invalid axle identity.");
    exception = addCause(exception, cause);
    throwAsCaller(exception);
end
if string(identity.frontAxleIdentity.axleId) ~= "FRONT" || ...
        ~isFiniteSize(identity.leftInnerStatic_m, [1, 3]) || ...
        ~isFiniteSize(identity.rightInnerStatic_m, [1, 3]) || ...
        ~isFiniteSize(identity.rackAxisDirection, [1, 3]) || ...
        ~isFiniteScalar(identity.rearAxleX_m)
    invalid("Steering identity fields have invalid values.");
end
tolerances = fsd.model.numericTolerances();
axisVector_m = identity.rightInnerStatic_m - identity.leftInnerStatic_m;
axisLength_m = norm(axisVector_m);
scale_m = max([norm(identity.leftInnerStatic_m), ...
    norm(identity.rightInnerStatic_m), 1]);
if axisLength_m <= tolerances.AbsTol_m + tolerances.RelTol * scale_m
    invalid("Rack identity endpoints must not coincide.");
end
if abs(norm(identity.rackAxisDirection) - 1) > ...
        tolerances.AbsTol_m + tolerances.RelTol
    invalid("rackAxisDirection must be unit length.");
end
expectedAxis = axisVector_m ./ axisLength_m;
if max(abs(identity.rackAxisDirection - expectedAxis)) > ...
        10 * (tolerances.AbsTol_m + tolerances.RelTol)
    invalid("rackAxisDirection must point from the left endpoint to the right.");
end
leftTie_m = identityPoint(identity.frontAxleIdentity.leftGeometryIdentity, ...
    "FL_TIE_ROD_INBOARD");
rightTie_m = identityPoint(identity.frontAxleIdentity.rightGeometryIdentity, ...
    "FR_TIE_ROD_INBOARD");
pointTolerance_m = 10*(tolerances.AbsTol_m + tolerances.RelTol* ...
    max([abs(leftTie_m),abs(rightTie_m),1]));
if max(abs(identity.leftInnerStatic_m-leftTie_m)) > pointTolerance_m || ...
        max(abs(identity.rightInnerStatic_m-rightTie_m)) > pointTolerance_m
    invalid("Rack endpoints must match the corner tie-rod inboard points.");
end
isValid = true;
end

function point_m = identityPoint(identity, id)
row = identity.hardpointIds == id;
if nnz(row) ~= 1
    invalid("Steering geometry identity is missing a tie-rod point.");
end
point_m = identity.hardpointXyz_m(row,:);
end

function tf = isFiniteSize(value, expectedSize)
tf = isnumeric(value) && isreal(value) && ...
    isequal(size(value), expectedSize) && all(isfinite(value));
end

function tf = isFiniteScalar(value)
tf = isnumeric(value) && isreal(value) && isscalar(value) && isfinite(value);
end

function invalid(message)
error("fsd:model:InvalidSteeringSystemIdentity", message);
end
