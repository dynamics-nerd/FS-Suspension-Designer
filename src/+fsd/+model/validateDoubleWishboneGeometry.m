function isValid = validateDoubleWishboneGeometry(geometry)
%VALIDATEDOUBLEWISHBONEGEOMETRY Validate the canonical v0.2 geometry.
%   Throws errors with stable fsd:model:* identifiers. Returns true when
%   the complete structure is valid.

if ~isstruct(geometry) || ~isscalar(geometry)
    error("fsd:model:InvalidGeometryType", ...
        "Geometry must be a scalar struct.");
end
requiredTopFields = ["schemaVersion", "kind", "cornerId", ...
    "referenceFrame", "hardpoints", "connectivity", "upright", ...
    "wheel", "metadata"];
requireFields(geometry, requiredTopFields, "fsd:model:InvalidSchema");

if string(geometry.schemaVersion) ~= "0.2.0" || ...
        string(geometry.kind) ~= "DoubleWishboneGeometry"
    error("fsd:model:InvalidSchema", ...
        "Unsupported or invalid DoubleWishboneGeometry schema.");
end

cornerId = normalizeCorner(geometry.cornerId);
hardpoints = geometry.hardpoints;
if ~isstruct(hardpoints) || ~isscalar(hardpoints)
    error("fsd:model:InvalidSchema", ...
        "hardpoints must be a scalar struct.");
end
requireFields(hardpoints, ...
    ["ids", "xyz_m", "sourceKind", "sourceNote", "displayName"], ...
    "fsd:model:InvalidSchema");

ids = validateIds(hardpoints.ids);
xyz_m = validateCoordinates(hardpoints.xyz_m, numel(ids));
validateProvenance(hardpoints, numel(ids));
validateDisplayNames(hardpoints.displayName, numel(ids));
validateRequiredIds(ids, cornerId);
validateReferenceFrame(geometry.referenceFrame);
validateMetadata(geometry.metadata);
validateConnectivity(geometry.connectivity, ids);
validateUpright(geometry.upright, ids, cornerId);
validateWheel(geometry.wheel, ids, cornerId);
validateElementaryGeometry(ids, xyz_m, cornerId);

isValid = true;
end

function requireFields(value, names, errorId)
for index = 1:numel(names)
    if ~isfield(value, names(index))
        error(errorId, "Missing required field '%s'.", names(index));
    end
end
end

function cornerId = normalizeCorner(value)
if ~(ischar(value) || (isstring(value) && isscalar(value)))
    error("fsd:model:InvalidCorner", ...
        "Corner must be one of FL, FR, RL, or RR.");
end
cornerId = upper(strtrim(string(value)));
if ~ismember(cornerId, ["FL", "FR", "RL", "RR"])
    error("fsd:model:InvalidCorner", ...
        "Corner must be one of FL, FR, RL, or RR.");
end
end

function ids = validateIds(value)
if ~isstring(value) || ~iscolumn(value) || isempty(value) || ...
        any(ismissing(value)) || any(strlength(value) == 0)
    error("fsd:model:InvalidIds", ...
        "Canonical hardpoint IDs must be a nonempty string column vector.");
end
ids = value;
if numel(unique(ids)) ~= numel(ids)
    error("fsd:model:DuplicateId", ...
        "Hardpoint IDs must be unique.");
end
end

function xyz_m = validateCoordinates(value, pointCount)
if ~isnumeric(value) || ~isreal(value)
    error("fsd:model:InvalidXyzType", ...
        "xyz_m must be a real numeric N-by-3 matrix.");
end
if ~ismatrix(value) || ~isequal(size(value), [pointCount, 3])
    error("fsd:model:InvalidXyzShape", ...
        "xyz_m must contain one N-by-3 row for each ID.");
end
if any(~isfinite(value), "all")
    error("fsd:model:NonFiniteCoordinate", ...
        "xyz_m coordinates must be finite.");
end
xyz_m = double(value);
end

function validateProvenance(hardpoints, pointCount)
expectedSize = [pointCount, 3];
if ~isstring(hardpoints.sourceKind) || ...
        ~isequal(size(hardpoints.sourceKind), expectedSize) || ...
        ~isstring(hardpoints.sourceNote) || ...
        ~isequal(size(hardpoints.sourceNote), expectedSize)
    error("fsd:model:InvalidProvenanceShape", ...
        "sourceKind and sourceNote must both be N-by-3 string arrays.");
end
allowedKinds = ["KNOWN", "ASSUMED", "DERIVED", "UNSPECIFIED"];
if any(ismissing(hardpoints.sourceKind), "all") || ...
        any(~ismember(hardpoints.sourceKind, allowedKinds), "all")
    error("fsd:model:InvalidProvenanceKind", ...
        "Invalid sourceKind value.");
end
end

function validateDisplayNames(value, pointCount)
if ~isstring(value) || ~isequal(size(value), [pointCount, 1])
    error("fsd:model:InvalidDisplayNames", ...
        "displayName must be an N-by-1 string array.");
end
end

function validateRequiredIds(ids, cornerId)
prefix = cornerId + "_";
if any(~startsWith(ids, prefix))
    error("fsd:model:CornerPrefixMismatch", ...
        "Every hardpoint ID must use the geometry corner prefix.");
end
requiredIds = prefix + fsd.model.requiredHardpointRoles();
missing = requiredIds(~ismember(requiredIds, ids));
if ~isempty(missing)
    error("fsd:model:MissingRequiredId", ...
        "Missing required hardpoint ID: %s", missing(1));
end
unknown = ids(~ismember(ids, requiredIds));
if ~isempty(unknown)
    error("fsd:model:UnknownId", ...
        "Unknown v0.2 hardpoint ID: %s", unknown(1));
end
if numel(ids) ~= numel(requiredIds)
    error("fsd:model:InvalidIds", ...
        "v0.2 requires exactly one row for each required hardpoint ID.");
end
end

function validateReferenceFrame(value)
if ~isstruct(value) || ~isscalar(value)
    error("fsd:model:InvalidReferenceFrame", ...
        "referenceFrame must be a scalar struct.");
end
requireFields(value, ["id", "originDescription", "axisConvention"], ...
    "fsd:model:InvalidReferenceFrame");
if string(value.id) ~= "VEHICLE_GLOBAL" || ...
        string(value.axisConvention) ~= "X_REAR_Y_RIGHT_Z_UP"
    error("fsd:model:InvalidReferenceFrame", ...
        "Geometry must use the canonical vehicle-global frame.");
end
end

function validateMetadata(value)
if ~isstruct(value) || ~isscalar(value)
    error("fsd:model:InvalidMetadata", ...
        "metadata must be a scalar struct.");
end
requireFields(value, ["lengthUnit", "coordinateSystem"], ...
    "fsd:model:InvalidMetadata");
if string(value.lengthUnit) ~= "m" || ...
        string(value.coordinateSystem) ~= "X_REAR_Y_RIGHT_Z_UP"
    error("fsd:model:InvalidMetadata", ...
        "Canonical geometry metadata must declare metres and the project frame.");
end
end

function validateConnectivity(value, ids)
if ~isstruct(value) || ~isscalar(value)
    error("fsd:model:InvalidConnectivity", ...
        "connectivity must be a scalar struct.");
end
requireFields(value, ["memberIds", "pointIds"], ...
    "fsd:model:InvalidConnectivity");
if ~isstring(value.memberIds) || ~iscolumn(value.memberIds) || ...
        ~isstring(value.pointIds) || size(value.pointIds, 2) ~= 2 || ...
        size(value.pointIds, 1) ~= numel(value.memberIds) || ...
        any(~ismember(value.pointIds, ids), "all")
    error("fsd:model:InvalidConnectivity", ...
        "Connectivity must reference existing point IDs in N-by-2 pairs.");
end
end

function validateUpright(value, ids, cornerId)
if ~isstruct(value) || ~isscalar(value) || ~isfield(value, "pointIds") || ...
        ~isstring(value.pointIds) || ~iscolumn(value.pointIds)
    error("fsd:model:InvalidUpright", ...
        "upright.pointIds must be a string column vector.");
end
required = cornerId + "_" + [ ...
    "UBJ"; "LBJ"; "TIE_ROD_OUTBOARD"; ...
    "WHEEL_CENTER"; "CONTACT_PATCH"];
if ~isequal(value.pointIds, required) || any(~ismember(value.pointIds, ids))
    error("fsd:model:InvalidUpright", ...
        "Upright references do not match the canonical rigid body.");
end
end

function validateWheel(value, ids, cornerId)
if ~isstruct(value) || ~isscalar(value)
    error("fsd:model:InvalidWheel", "wheel must be a scalar struct.");
end
requireFields(value, ["centerId", "contactPatchId", "wheelAxis"], ...
    "fsd:model:InvalidWheel");
expectedCenter = cornerId + "_WHEEL_CENTER";
expectedContact = cornerId + "_CONTACT_PATCH";
if string(value.centerId) ~= expectedCenter || ...
        string(value.contactPatchId) ~= expectedContact || ...
        ~ismember(expectedCenter, ids) || ~ismember(expectedContact, ids)
    error("fsd:model:InvalidWheel", ...
        "Wheel references must match the geometry corner.");
end
axis = value.wheelAxis;
if ~isnumeric(axis) || ~isreal(axis) || ~isequal(size(axis), [1, 3]) || ...
        any(~isfinite(axis))
    error("fsd:model:InvalidWheelAxis", ...
        "wheelAxis must be a finite real 1-by-3 vector.");
end
tolerances = fsd.model.numericTolerances();
axisNorm = norm(double(axis), 2);
if axisNorm <= tolerances.AbsTol_m
    error("fsd:model:ZeroWheelAxis", "wheelAxis must be nonzero.");
end
if abs(axisNorm - 1) > tolerances.AbsTol_m + tolerances.RelTol
    error("fsd:model:WheelAxisNotUnit", ...
        "Canonical wheelAxis must have unit length.");
end
outwardY = 1;
if ismember(cornerId, ["FL", "RL"])
    outwardY = -1;
end
if axis(2) * outwardY <= tolerances.AbsTol_m
    error("fsd:model:WheelAxisNotOutward", ...
        "wheelAxis must have a positive component toward wheel exterior.");
end
end

function validateElementaryGeometry(ids, xyz_m, cornerId)
assertDistinct(ids, xyz_m, cornerId + "_UBJ", cornerId + "_LBJ", ...
    "fsd:model:CoincidentUBJLBJ");
assertDistinct(ids, xyz_m, cornerId + "_UCA_FWD_CHASSIS", ...
    cornerId + "_UCA_AFT_CHASSIS", "fsd:model:CoincidentUcaPivots");
assertDistinct(ids, xyz_m, cornerId + "_LCA_FWD_CHASSIS", ...
    cornerId + "_LCA_AFT_CHASSIS", "fsd:model:CoincidentLcaPivots");
assertDistinct(ids, xyz_m, cornerId + "_WHEEL_CENTER", ...
    cornerId + "_CONTACT_PATCH", ...
    "fsd:model:CoincidentWheelReferences");
assertDistinct(ids, xyz_m, cornerId + "_TIE_ROD_INBOARD", ...
    cornerId + "_TIE_ROD_OUTBOARD", "fsd:model:CoincidentTieRod");
assertDistinct(ids, xyz_m, cornerId + "_UBJ", ...
    cornerId + "_TIE_ROD_OUTBOARD", ...
    "fsd:model:CoincidentUprightPoints");
assertDistinct(ids, xyz_m, cornerId + "_LBJ", ...
    cornerId + "_TIE_ROD_OUTBOARD", ...
    "fsd:model:CoincidentUprightPoints");
assertDistinct(ids, xyz_m, cornerId + "_UCA_FWD_CHASSIS", ...
    cornerId + "_UBJ", "fsd:model:ZeroLengthUcaLink");
assertDistinct(ids, xyz_m, cornerId + "_UCA_AFT_CHASSIS", ...
    cornerId + "_UBJ", "fsd:model:ZeroLengthUcaLink");
assertDistinct(ids, xyz_m, cornerId + "_LCA_FWD_CHASSIS", ...
    cornerId + "_LBJ", "fsd:model:ZeroLengthLcaLink");
assertDistinct(ids, xyz_m, cornerId + "_LCA_AFT_CHASSIS", ...
    cornerId + "_LBJ", "fsd:model:ZeroLengthLcaLink");
assertNoncollinearUpright(ids, xyz_m, cornerId);
end

function assertNoncollinearUpright(ids, xyz_m, cornerId)
ubj = xyz_m(ids == cornerId + "_UBJ", :);
lbj = xyz_m(ids == cornerId + "_LBJ", :);
tieOut = xyz_m(ids == cornerId + "_TIE_ROD_OUTBOARD", :);
v1 = lbj - ubj;
v2 = tieOut - ubj;
areaMeasure_m2 = norm(cross(v1, v2), 2);
tolerances = fsd.model.numericTolerances();
scale_m = max([norm(v1, 2), norm(v2, 2), 1]);
threshold_m2 = tolerances.AbsTol_m * scale_m + ...
    tolerances.RelTol * norm(v1, 2) * norm(v2, 2);
if areaMeasure_m2 <= threshold_m2
    error("fsd:model:DegenerateUpright", ...
        "UBJ, LBJ, and TIE_ROD_OUTBOARD must not be collinear.");
end
end

function assertDistinct(ids, xyz_m, idA, idB, errorId)
pointA = xyz_m(ids == idA, :);
pointB = xyz_m(ids == idB, :);
tolerances = fsd.model.numericTolerances();
scale = max([norm(pointA, 2), norm(pointB, 2), 1]);
if norm(pointB - pointA, 2) <= ...
        tolerances.AbsTol_m + tolerances.RelTol * scale
    error(errorId, "%s and %s must not be coincident.", idA, idB);
end
end
