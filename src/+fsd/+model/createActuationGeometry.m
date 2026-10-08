function actuation = createActuationGeometry( ...
    cornerGeometry, definition, inputUnit)
%CREATEACTUATIONGEOMETRY Build a canonical optional corner actuation model.
%   DEFINITION contains actuationType, suspensionAttachment, rocker and
%   damper. Public point inputs use INPUTUNIT "m" or "mm".

fsd.model.validateDoubleWishboneGeometry(cornerGeometry);
if ~isstruct(definition) || ~isscalar(definition)
    invalid("definition must be a scalar struct.");
end
requireFields(definition, ...
    ["actuationType", "suspensionAttachment", "rocker", "damper"]);

actuationType = textChoice(definition.actuationType, ...
    ["PUSHROD", "PULLROD"], "actuationType");
attachment = definition.suspensionAttachment;
if ~isstruct(attachment) || ~isscalar(attachment)
    invalid("suspensionAttachment must be a scalar struct.");
end
requireFields(attachment, ["body", "point"]);
attachmentBody = textChoice(attachment.body, ...
    ["UPRIGHT", "UCA", "LCA"], "suspensionAttachment.body");
attachmentPoint_m = pointToMetres(attachment.point, inputUnit, ...
    "suspensionAttachment.point");

rocker = definition.rocker;
if ~isstruct(rocker) || ~isscalar(rocker)
    invalid("rocker must be a scalar struct.");
end
requireFields(rocker, ["orientationMode", "axis", ...
    "actuationRodPoint", "damperPoint"]);
orientationMode = textChoice(rocker.orientationMode, ...
    ["YZ_PLANE", "XZ_PLANE", "CUSTOM"], "rocker.orientationMode");
if ~isstruct(rocker.axis) || ~isscalar(rocker.axis)
    invalid("rocker.axis must be a scalar struct.");
end
requireFields(rocker.axis, "point");
axisPointRaw_m = pointToMetres(rocker.axis.point, inputUnit, ...
    "rocker.axis.point");
axisDirection = orientationDirection(rocker.axis, orientationMode);
% Canonical line point: the unique point on the axis nearest the origin.
axisPoint_m = axisPointRaw_m - dot(axisPointRaw_m, axisDirection) .* ...
    axisDirection;
% Remove projection round-off so equivalent points on the same line have
% an exact canonical identity. This is numerical canonicalization at a
% scale far below the project's software geometry tolerance.
axisPoint_m = round(axisPoint_m, 14);
rockerRodPoint_m = pointToMetres(rocker.actuationRodPoint, inputUnit, ...
    "rocker.actuationRodPoint");
rockerDamperPoint_m = pointToMetres(rocker.damperPoint, inputUnit, ...
    "rocker.damperPoint");

damper = definition.damper;
if ~isstruct(damper) || ~isscalar(damper)
    invalid("damper must be a scalar struct.");
end
requireFields(damper, "chassisPoint");
damperChassisPoint_m = pointToMetres(damper.chassisPoint, inputUnit, ...
    "damper.chassisPoint");

metadata = struct();
if isfield(definition, "metadata")
    if ~isstruct(definition.metadata) || ~isscalar(definition.metadata)
        invalid("metadata must be a scalar struct.");
    end
    metadata = definition.metadata;
end
metadata.lengthUnit = "m";
metadata.coordinateSystem = "X_REAR_Y_RIGHT_Z_UP";

rodLength_m = norm(attachmentPoint_m - rockerRodPoint_m, 2);
damperLength_m = norm(rockerDamperPoint_m - damperChassisPoint_m, 2);
actuation = struct( ...
    "schemaVersion", "0.7.0", ...
    "kind", "ActuationGeometry", ...
    "cornerId", string(cornerGeometry.cornerId), ...
    "cornerGeometryIdentity", fsd.model.geometryIdentity(cornerGeometry), ...
    "actuationType", actuationType, ...
    "suspensionAttachment", struct( ...
        "id", "ACTUATION_ROD_SUSPENSION", ...
        "body", attachmentBody, ...
        "pointStatic_m", attachmentPoint_m), ...
    "rocker", struct( ...
        "orientationMode", orientationMode, ...
        "axis", struct( ...
            "point_m", axisPoint_m, ...
            "direction_unit", axisDirection, ...
            "pointConvention", "CLOSEST_TO_VEHICLE_ORIGIN"), ...
        "actuationRodPoint", struct( ...
            "id", "ACTUATION_ROD_ROCKER", ...
            "pointStatic_m", rockerRodPoint_m), ...
        "damperPoint", struct( ...
            "id", "DAMPER_ROCKER", ...
            "pointStatic_m", rockerDamperPoint_m)), ...
    "damper", struct( ...
        "chassisPoint", struct( ...
            "id", "DAMPER_CHASSIS", ...
            "point_m", damperChassisPoint_m), ...
        "staticLength_m", damperLength_m), ...
    "actuationRod", struct("staticLength_m", rodLength_m), ...
    "metadata", metadata);
actuation.identity = fsd.model.actuationIdentity(actuation);
fsd.model.validateActuationGeometry(actuation);
end

function direction = orientationDirection(axis, mode)
if mode == "YZ_PLANE"
    direction = [1, 0, 0];
elseif mode == "XZ_PLANE"
    direction = [0, 1, 0];
else
    requireFields(axis, "direction");
    value = axis.direction;
    if ~isnumeric(value) || ~isreal(value) || ...
            ~isequal(size(value), [1, 3]) || any(~isfinite(value))
        invalid("rocker.axis.direction must be a finite real 1-by-3 vector.");
    end
    axisNorm = norm(double(value), 2);
    tolerances = fsd.model.numericTolerances();
    if axisNorm <= tolerances.AbsTol_m
        invalid("CUSTOM rocker axis direction must be nonzero.");
    end
    direction = double(value) ./ axisNorm;
    return
end
if isfield(axis, "direction")
    value = axis.direction;
    if ~isnumeric(value) || ~isreal(value) || ...
            ~isequal(size(value), [1, 3]) || any(~isfinite(value)) || ...
            norm(value) == 0
        invalid("Preset rocker axis direction must be a finite nonzero vector.");
    end
    supplied = double(value) ./ norm(double(value), 2);
    if norm(supplied-direction, 2) > 10*eps
        invalid("Preset rocker axis direction contradicts orientationMode.");
    end
end
end

function point_m = pointToMetres(value, inputUnit, fieldName)
if ~isnumeric(value) || ~isreal(value) || ~isequal(size(value), [1, 3])
    invalid("%s must be a real numeric 1-by-3 point.", fieldName);
end
point_m = fsd.model.convertLengthToMetres(value, inputUnit);
end

function value = textChoice(input, allowed, fieldName)
if ~((ischar(input) && isrow(input)) || ...
        (isstring(input) && isscalar(input) && ~ismissing(input)))
    invalid("%s must be a text scalar.", fieldName);
end
value = upper(strtrim(string(input)));
if ~ismember(value, allowed)
    invalid("%s has an unsupported value.", fieldName);
end
end

function requireFields(value, names)
for index = 1:numel(names)
    if ~isfield(value, names(index))
        invalid("Missing required field '%s'.", names(index));
    end
end
end

function invalid(message, varargin)
error("fsd:model:InvalidActuationDefinition", message, varargin{:});
end
