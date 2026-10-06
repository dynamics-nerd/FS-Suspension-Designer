function geometry = createDoubleWishboneGeometry( ...
    cornerId, ids, xyz, inputUnit, wheelAxis, provenance)
%CREATEDOUBLEWISHBONEGEOMETRY Build a canonical v0.2 corner geometry.
%   GEOMETRY = fsd.model.createDoubleWishboneGeometry(CORNERID, IDS, XYZ,
%   INPUTUNIT, WHEELAXIS) accepts INPUTUNIT "m" or "mm" and stores XYZ in
%   metres. WHEELAXIS points from vehicle interior toward wheel exterior.
%
%   An optional PROVENANCE struct can contain sourceKind and sourceNote.
%   Each value may be scalar, N-by-1, or N-by-3 and is expanded to N-by-3.

if nargin < 6 || isempty(provenance)
    provenance = struct();
end

cornerId = normalizeCorner(cornerId);
ids = normalizeIds(ids);
if ~isnumeric(xyz) || ~isreal(xyz)
    error("fsd:model:InvalidXyzType", ...
        "XYZ must be a real numeric N-by-3 matrix.");
end
if isvector(xyz) || ~ismatrix(xyz) || size(xyz, 2) ~= 3
    error("fsd:model:InvalidXyzShape", ...
        "XYZ must be an N-by-3 matrix with one hardpoint per row.");
end
if any(~isfinite(xyz), "all")
    error("fsd:model:NonFiniteCoordinate", ...
        "XYZ coordinates must be finite.");
end
xyz_m = fsd.model.convertLengthToMetres(xyz, inputUnit);

pointCount = numel(ids);
if size(xyz_m, 1) ~= pointCount
    error("fsd:model:IdCoordinateCountMismatch", ...
        "The number of IDs must equal the number of XYZ rows.");
end

[sourceKind, sourceNote] = normalizeProvenance(provenance, pointCount);
wheelAxis = normalizeWheelAxis(wheelAxis);

roles = extractRoles(ids, cornerId);
geometry = struct();
geometry.schemaVersion = "0.2.0";
geometry.kind = "DoubleWishboneGeometry";
geometry.cornerId = cornerId;
geometry.referenceFrame = struct( ...
    "id", "VEHICLE_GLOBAL", ...
    "originDescription", ...
    "Midpoint between front contact patches on nominal ground plane", ...
    "axisConvention", "X_REAR_Y_RIGHT_Z_UP");
geometry.hardpoints = struct( ...
    "ids", ids, ...
    "xyz_m", xyz_m, ...
    "sourceKind", sourceKind, ...
    "sourceNote", sourceNote, ...
    "displayName", displayNamesForRoles(roles));

geometry.connectivity = buildConnectivity(cornerId);
geometry.upright = struct( ...
    "pointIds", cornerId + "_" + [ ...
    "UBJ"; "LBJ"; "TIE_ROD_OUTBOARD"; ...
    "WHEEL_CENTER"; "CONTACT_PATCH"]);
geometry.wheel = struct( ...
    "centerId", cornerId + "_WHEEL_CENTER", ...
    "contactPatchId", cornerId + "_CONTACT_PATCH", ...
    "wheelAxis", wheelAxis);
geometry.metadata = struct( ...
    "lengthUnit", "m", ...
    "coordinateSystem", "X_REAR_Y_RIGHT_Z_UP");

fsd.model.validateDoubleWishboneGeometry(geometry);
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

function ids = normalizeIds(value)
if ~(isstring(value) || iscellstr(value) || ischar(value))
    error("fsd:model:InvalidIds", ...
        "Hardpoint IDs must be text values.");
end
ids = upper(strtrim(string(value)));
ids = ids(:);
if isempty(ids) || any(ismissing(ids)) || any(strlength(ids) == 0)
    error("fsd:model:InvalidIds", ...
        "Hardpoint IDs must be nonempty text values.");
end
end

function [sourceKind, sourceNote] = normalizeProvenance(value, pointCount)
if ~isstruct(value) || ~isscalar(value)
    error("fsd:model:InvalidProvenance", ...
        "Provenance must be a scalar struct.");
end
if isfield(value, "sourceKind")
    sourceKind = expandText(value.sourceKind, pointCount, ...
        "fsd:model:InvalidProvenanceShape", "sourceKind");
else
    sourceKind = repmat("UNSPECIFIED", pointCount, 3);
end
sourceKind = upper(strtrim(sourceKind));
allowedKinds = ["KNOWN", "ASSUMED", "DERIVED", "UNSPECIFIED"];
if any(ismissing(sourceKind), "all") || ...
        any(strlength(sourceKind) == 0, "all") || ...
        any(~ismember(sourceKind, allowedKinds), "all")
    error("fsd:model:InvalidProvenanceKind", ...
        "sourceKind values must be KNOWN, ASSUMED, DERIVED, or UNSPECIFIED.");
end

if isfield(value, "sourceNote")
    sourceNote = expandText(value.sourceNote, pointCount, ...
        "fsd:model:InvalidProvenanceShape", "sourceNote");
else
    sourceNote = strings(pointCount, 3);
end
sourceNote(ismissing(sourceNote)) = "";
end

function output = expandText(value, pointCount, errorId, fieldName)
if ~(isstring(value) || iscellstr(value) || ischar(value))
    error(errorId, "%s must contain text values.", fieldName);
end
output = string(value);
if isscalar(output)
    output = repmat(output, pointCount, 3);
elseif isequal(size(output), [pointCount, 1])
    output = repmat(output, 1, 3);
elseif ~isequal(size(output), [pointCount, 3])
    error(errorId, ...
        "%s must be scalar, N-by-1, or N-by-3.", fieldName);
end
end

function wheelAxis = normalizeWheelAxis(value)
if ~isnumeric(value) || ~isreal(value) || ~isequal(size(value), [1, 3])
    error("fsd:model:InvalidWheelAxis", ...
        "wheelAxis must be a real numeric 1-by-3 vector.");
end
if any(~isfinite(value))
    error("fsd:model:InvalidWheelAxis", ...
        "wheelAxis must contain only finite values.");
end
axisNorm = norm(double(value), 2);
tolerances = fsd.model.numericTolerances();
if axisNorm <= tolerances.AbsTol_m
    error("fsd:model:ZeroWheelAxis", ...
        "wheelAxis must be nonzero.");
end
wheelAxis = double(value) ./ axisNorm;
end

function roles = extractRoles(ids, cornerId)
prefix = cornerId + "_";
roles = strings(size(ids));
for index = 1:numel(ids)
    if startsWith(ids(index), prefix)
        roles(index) = extractAfter(ids(index), strlength(prefix));
    else
        roles(index) = ids(index);
    end
end
end

function names = displayNamesForRoles(roles)
names = replace(lower(roles), "_", " ");
names = rolesToDisplay(roles, names);
end

function names = rolesToDisplay(roles, names)
knownRoles = fsd.model.requiredHardpointRoles();
knownNames = [ ...
    "UCA forward chassis pivot"; ...
    "UCA aft chassis pivot"; ...
    "Upper ball joint"; ...
    "LCA forward chassis pivot"; ...
    "LCA aft chassis pivot"; ...
    "Lower ball joint"; ...
    "Tie rod inboard"; ...
    "Tie rod outboard"; ...
    "Wheel center"; ...
    "Contact patch"];
for index = 1:numel(roles)
    match = find(knownRoles == roles(index), 1);
    if ~isempty(match)
        names(index) = knownNames(match);
    end
end
names = names(:);
end

function connectivity = buildConnectivity(cornerId)
prefix = cornerId + "_";
connectivity = struct();
connectivity.memberIds = [ ...
    "UCA_FWD_LEG"; "UCA_AFT_LEG"; ...
    "LCA_FWD_LEG"; "LCA_AFT_LEG"; ...
    "TIE_ROD"; "UPRIGHT"; "WHEEL_REFERENCE"];
connectivity.pointIds = [ ...
    prefix + "UCA_FWD_CHASSIS", prefix + "UBJ"; ...
    prefix + "UCA_AFT_CHASSIS", prefix + "UBJ"; ...
    prefix + "LCA_FWD_CHASSIS", prefix + "LBJ"; ...
    prefix + "LCA_AFT_CHASSIS", prefix + "LBJ"; ...
    prefix + "TIE_ROD_INBOARD", prefix + "TIE_ROD_OUTBOARD"; ...
    prefix + "UBJ", prefix + "LBJ"; ...
    prefix + "WHEEL_CENTER", prefix + "CONTACT_PATCH"];
end
