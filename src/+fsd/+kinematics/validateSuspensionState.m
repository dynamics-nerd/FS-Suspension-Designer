function isValid = validateSuspensionState( ...
    state, geometryIdentity, expectedPayload)
%VALIDATESUSPENSIONSTATE Validate the complete v0.2 state contract.
%   EXPECTEDPAYLOAD is "FINITE" for a converged result or "NAN" for a
%   result that did not converge or was not attempted.

validateIdentity(geometryIdentity);
expectedPayload = normalizeExpectedPayload(expectedPayload);
if ~isstruct(state) || ~isscalar(state)
    invalid("SuspensionState must be a scalar struct.");
end
required = ["schemaVersion", "kind", "pointIds", "xyz_m", ...
    "ubj_m", "lbj_m", "tieRodOutboard_m", "wheelCenter_m", ...
    "contactPatch_m", "wheelAxis", "wheelTravel_m"];
for index = 1:numel(required)
    if ~isfield(state, required(index))
        invalid("SuspensionState is missing field '%s'.", required(index));
    end
end
if ~isTextScalar(state.schemaVersion) || ...
        string(state.schemaVersion) ~= "0.2.0" || ...
        ~isTextScalar(state.kind) || string(state.kind) ~= "SuspensionState"
    invalid("Unsupported or invalid SuspensionState schema.");
end

expectedIds = string(geometryIdentity.cornerId) + "_" + [ ...
    "UBJ"; "LBJ"; "TIE_ROD_OUTBOARD"; ...
    "WHEEL_CENTER"; "CONTACT_PATCH"];
if ~isstring(state.pointIds) || ~isequal(state.pointIds, expectedIds)
    invalid("SuspensionState pointIds must match the canonical upright order.");
end
if ~isRealNumericSize(state.xyz_m, [5, 3]) || ...
        ~isRealNumericSize(state.ubj_m, [1, 3]) || ...
        ~isRealNumericSize(state.lbj_m, [1, 3]) || ...
        ~isRealNumericSize(state.tieRodOutboard_m, [1, 3]) || ...
        ~isRealNumericSize(state.wheelCenter_m, [1, 3]) || ...
        ~isRealNumericSize(state.contactPatch_m, [1, 3]) || ...
        ~isRealNumericSize(state.wheelAxis, [1, 3]) || ...
        ~isnumeric(state.wheelTravel_m) || ~isreal(state.wheelTravel_m) || ...
        ~isscalar(state.wheelTravel_m)
    invalid("SuspensionState numeric fields have invalid types or dimensions.");
end

conveniencePoints_m = [ ...
    state.ubj_m; state.lbj_m; state.tieRodOutboard_m; ...
    state.wheelCenter_m; state.contactPatch_m];
if ~isequaln(double(state.xyz_m), double(conveniencePoints_m))
    invalid("SuspensionState convenience points contradict xyz_m.");
end

switch expectedPayload
    case "FINITE"
        if any(~isfinite(state.xyz_m), "all") || ...
                any(~isfinite(state.wheelAxis)) || ...
                ~isfinite(state.wheelTravel_m)
            invalid("A converged SuspensionState must contain finite data.");
        end
        tolerances = fsd.model.numericTolerances();
        if abs(norm(double(state.wheelAxis), 2) - 1) > ...
                tolerances.AbsTol_m + tolerances.RelTol
            invalid("SuspensionState wheelAxis must be unit length.");
        end
        sideSign = 1;
        if ismember(string(geometryIdentity.cornerId), ["FL", "RL"])
            sideSign = -1;
        end
        if sideSign * state.wheelAxis(2) <= tolerances.RelTol
            invalid("SuspensionState wheelAxis must point toward wheel exterior.");
        end
    case "NAN"
        if ~all(isnan(state.xyz_m), "all") || ...
                ~all(isnan(state.wheelAxis)) || ...
                ~isnan(state.wheelTravel_m)
            invalid("A non-converged SuspensionState must use an all-NaN payload.");
        end
end
isValid = true;
end

function validateIdentity(identity)
try
    fsd.model.validateGeometryIdentity(identity);
catch cause
    exception = MException("fsd:kinematics:InvalidSuspensionState", ...
        "SuspensionState has an invalid geometry identity context.");
    exception = addCause(exception, cause);
    throwAsCaller(exception);
end
end

function value = normalizeExpectedPayload(value)
if ~isTextScalar(value)
    invalid("expectedPayload must be FINITE or NAN.");
end
value = upper(strtrim(string(value)));
if ~ismember(value, ["FINITE", "NAN"])
    invalid("expectedPayload must be FINITE or NAN.");
end
end

function tf = isRealNumericSize(value, expectedSize)
tf = isnumeric(value) && isreal(value) && isequal(size(value), expectedSize);
end

function tf = isTextScalar(value)
tf = (ischar(value) && isrow(value)) || ...
    (isstring(value) && isscalar(value) && ~ismissing(value));
end

function invalid(message, varargin)
error("fsd:kinematics:InvalidSuspensionState", message, varargin{:});
end
