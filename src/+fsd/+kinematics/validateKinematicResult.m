function isValid = validateKinematicResult(result)
%VALIDATEKINEMATICRESULT Validate a complete geometry-bound result.

if ~isstruct(result) || ~isscalar(result)
    invalid("KinematicResult must be a scalar struct.");
end
required = ["schemaVersion", "kind", "geometryIdentity", ...
    "requestedWheelTravel_m", "achievedWheelTravel_m", "converged", ...
    "status", "failureReason", "state", "uprightPose", ...
    "wheelAxis", "camber_rad", "diagnostics"];
for index = 1:numel(required)
    if ~isfield(result, required(index))
        invalid("KinematicResult is missing field '%s'.", required(index));
    end
end
if ~isTextScalar(result.schemaVersion) || ...
        string(result.schemaVersion) ~= "0.3.0" || ...
        ~isTextScalar(result.kind) || string(result.kind) ~= "KinematicResult"
    invalid("Unsupported or invalid KinematicResult schema.");
end
validateIdentity(result.geometryIdentity);

if ~isnumeric(result.requestedWheelTravel_m) || ...
        ~isreal(result.requestedWheelTravel_m) || ...
        ~isscalar(result.requestedWheelTravel_m) || ...
        ~isfinite(result.requestedWheelTravel_m) || ...
        ~isnumeric(result.achievedWheelTravel_m) || ...
        ~isreal(result.achievedWheelTravel_m) || ...
        ~isscalar(result.achievedWheelTravel_m) || ...
        ~islogical(result.converged) || ~isscalar(result.converged) || ...
        ~isTextScalar(result.status) || ...
        ~isTextScalar(result.failureReason) || ...
        ~isRealNumericSize(result.wheelAxis, [1, 3]) || ...
        ~isnumeric(result.camber_rad) || ~isreal(result.camber_rad) || ...
        ~isscalar(result.camber_rad)
    invalid("KinematicResult fields have invalid types or dimensions.");
end
status = string(result.status);
validateDiagnostics(result.diagnostics);
if result.converged
    if status ~= "CONVERGED"
        invalid("converged=true requires status CONVERGED.");
    end
    validateConvergedPayload(result);
else
    if ~ismember(status, ["NO_CONVERGENCE", "NOT_ATTEMPTED"])
        invalid("converged=false requires NO_CONVERGENCE or NOT_ATTEMPTED.");
    end
    validateFailedPayload(result);
end
validateAttempted(status, result.converged, result.diagnostics);
isValid = true;
end

function validateConvergedPayload(result)
if ~isfinite(result.achievedWheelTravel_m) || ...
        any(~isfinite(result.wheelAxis)) || ~isfinite(result.camber_rad) || ...
        strlength(string(result.failureReason)) ~= 0
    invalid("A converged result requires finite data and no failureReason.");
end
fsd.kinematics.validateSuspensionState( ...
    result.state, result.geometryIdentity, "FINITE");
pose = validatePose(result.uprightPose, result.geometryIdentity, "FINITE");

tolerance = comparisonTolerance(result.geometryIdentity.hardpointXyz_m);
if max(abs(result.state.wheelAxis - result.wheelAxis)) > tolerance || ...
        abs(result.state.wheelTravel_m - ...
        result.achievedWheelTravel_m) > tolerance || ...
        abs(result.requestedWheelTravel_m - ...
        result.achievedWheelTravel_m) > tolerance
    invalid("KinematicResult redundant travel or wheel-axis fields disagree.");
end

[staticPoints_m, wheelCenterStatic_m] = staticMovingPoints( ...
    result.geometryIdentity);
expectedPoints_m = fsd.geometry.transformPointsRigid( ...
    staticPoints_m, wheelCenterStatic_m, pose.translation_m, ...
    pose.rotationMatrix);
expectedAxis = (pose.rotationMatrix * ...
    result.geometryIdentity.wheelAxis(:))';
expectedAxis = expectedAxis ./ norm(expectedAxis, 2);
expectedTravel_m = expectedPoints_m(4, 3) - wheelCenterStatic_m(3);
if max(abs(expectedPoints_m - result.state.xyz_m), [], "all") > ...
        tolerance || ...
        max(abs(expectedAxis - result.wheelAxis)) > tolerance || ...
        abs(expectedTravel_m - result.achievedWheelTravel_m) > tolerance
    invalid("KinematicResult state contradicts its upright pose.");
end

expectedCamber_rad = fsd.kinematics.camberFromWheelAxis( ...
    result.wheelAxis, result.geometryIdentity.cornerId);
if abs(expectedCamber_rad - result.camber_rad) > tolerance
    invalid("KinematicResult camber contradicts its wheel axis.");
end
validateExternalConstraints(result.geometryIdentity, result.state);
end

function validateFailedPayload(result)
if ~isnan(result.achievedWheelTravel_m) || ...
        ~all(isnan(result.wheelAxis)) || ~isnan(result.camber_rad) || ...
        strlength(string(result.failureReason)) == 0 || ...
        string(result.failureReason) ~= string(result.diagnostics.message)
    invalid("A non-converged result requires NaN outputs and a failureReason.");
end
fsd.kinematics.validateSuspensionState( ...
    result.state, result.geometryIdentity, "NAN");
validatePose(result.uprightPose, result.geometryIdentity, "NAN");
end

function pose = validatePose(pose, identity, expectedPayload)
if ~isstruct(pose) || ~isscalar(pose)
    invalid("uprightPose must be a scalar struct.");
end
required = ["referencePointStatic_m", "translation_m", ...
    "rotationVector_rad", "rotationMatrix"];
for index = 1:numel(required)
    if ~isfield(pose, required(index))
        invalid("uprightPose is missing field '%s'.", required(index));
    end
end
if ~isRealNumericSize(pose.referencePointStatic_m, [1, 3]) || ...
        ~isRealNumericSize(pose.translation_m, [1, 3]) || ...
        ~isRealNumericSize(pose.rotationVector_rad, [1, 3]) || ...
        ~isRealNumericSize(pose.rotationMatrix, [3, 3])
    invalid("uprightPose fields have invalid types or dimensions.");
end
[~, wheelCenterStatic_m] = staticMovingPoints(identity);
tolerance = comparisonTolerance(identity.hardpointXyz_m);
if any(~isfinite(pose.referencePointStatic_m)) || ...
        max(abs(pose.referencePointStatic_m - wheelCenterStatic_m)) > tolerance
    invalid("uprightPose reference point must equal the static wheel center.");
end

if expectedPayload == "FINITE"
    if any(~isfinite(pose.translation_m)) || ...
            any(~isfinite(pose.rotationVector_rad)) || ...
            any(~isfinite(pose.rotationMatrix), "all")
        invalid("A converged uprightPose must be finite.");
    end
    expectedRotation = fsd.geometry.rotationVectorToMatrix( ...
        pose.rotationVector_rad);
    if max(abs(expectedRotation - pose.rotationMatrix), [], "all") > ...
            tolerance
        invalid("uprightPose rotation vector and matrix disagree.");
    end
else
    if ~all(isnan(pose.translation_m)) || ...
            ~all(isnan(pose.rotationVector_rad)) || ...
            ~all(isnan(pose.rotationMatrix), "all")
        invalid("A non-converged uprightPose must use NaN pose fields.");
    end
end
end

function validateDiagnostics(value)
if ~isstruct(value) || ~isscalar(value)
    invalid("diagnostics must be a scalar struct.");
end
required = ["solver", "toolbox", "attempted", "constraintIds", ...
    "lengthErrors_m", "maxConstraintError_m", "residualVector", ...
    "residualNorm", "maxResidual", "exitFlag", "iterations", ...
    "functionEvaluations", "continuationSteps", "message"];
for index = 1:numel(required)
    if ~isfield(value, required(index))
        invalid("diagnostics is missing field '%s'.", required(index));
    end
end
expectedConstraints = [ ...
    "UCA_FWD"; "UCA_AFT"; "LCA_FWD"; "LCA_AFT"; "TIE_ROD"];
if ~isTextScalar(value.solver) || ~isTextScalar(value.toolbox) || ...
        ~islogical(value.attempted) || ~isscalar(value.attempted) || ...
        ~isstring(value.constraintIds) || ...
        ~isequal(value.constraintIds, expectedConstraints) || ...
        ~isRealNumericSize(value.lengthErrors_m, [5, 1]) || ...
        ~isRealNumericSize(value.residualVector, [5, 1]) || ...
        ~isRealNumericScalar(value.maxConstraintError_m) || ...
        ~isRealNumericScalar(value.residualNorm) || ...
        ~isRealNumericScalar(value.maxResidual) || ...
        ~isRealNumericScalar(value.exitFlag) || ...
        ~isNonnegativeFiniteScalar(value.iterations) || ...
        ~isNonnegativeFiniteScalar(value.functionEvaluations) || ...
        ~isNonnegativeFiniteScalar(value.continuationSteps) || ...
        ~isTextScalar(value.message)
    invalid("diagnostics fields violate the KinematicResult contract.");
end
end

function validateAttempted(status, converged, diagnostics)
expectedAttempted = status ~= "NOT_ATTEMPTED";
if diagnostics.attempted ~= expectedAttempted
    invalid("status and diagnostics.attempted are inconsistent.");
end
if converged && ~diagnostics.attempted
    invalid("A converged result must have diagnostics.attempted=true.");
end
if ~diagnostics.attempted && (diagnostics.iterations ~= 0 || ...
        diagnostics.functionEvaluations ~= 0 || ...
        diagnostics.continuationSteps ~= 0 || diagnostics.exitFlag ~= 0)
    invalid("NOT_ATTEMPTED diagnostics must not report solver activity.");
end
end

function validateExternalConstraints(identity, state)
cornerPrefix = string(identity.cornerId) + "_";
fixedIds = cornerPrefix + [ ...
    "UCA_FWD_CHASSIS"; "UCA_AFT_CHASSIS"; ...
    "LCA_FWD_CHASSIS"; "LCA_AFT_CHASSIS"; ...
    "TIE_ROD_INBOARD"];
movingStaticIds = cornerPrefix + [ ...
    "UBJ"; "UBJ"; "LBJ"; "LBJ"; "TIE_ROD_OUTBOARD"];
fixed_m = identityPoints(identity, fixedIds);
movingStatic_m = identityPoints(identity, movingStaticIds);
movingCurrent_m = [ ...
    state.ubj_m; state.ubj_m; state.lbj_m; state.lbj_m; ...
    state.tieRodOutboard_m];
staticLengths_m = sqrt(sum((movingStatic_m - fixed_m).^2, 2));
currentLengths_m = sqrt(sum((movingCurrent_m - fixed_m).^2, 2));
tolerances = fsd.model.numericTolerances();
constraintTolerance_m = tolerances.AbsTol_m + ...
    tolerances.RelTol * max([staticLengths_m; 1]);
if any(abs(currentLengths_m - staticLengths_m) > constraintTolerance_m)
    invalid("KinematicResult violates constraints from geometryIdentity.");
end
end

function points_m = identityPoints(identity, pointIds)
points_m = zeros(numel(pointIds), 3);
for index = 1:numel(pointIds)
    points_m(index, :) = identity.hardpointXyz_m( ...
        identity.hardpointIds == pointIds(index), :);
end
end

function [points_m, wheelCenter_m] = staticMovingPoints(identity)
ids = string(identity.cornerId) + "_" + [ ...
    "UBJ"; "LBJ"; "TIE_ROD_OUTBOARD"; ...
    "WHEEL_CENTER"; "CONTACT_PATCH"];
points_m = identityPoints(identity, ids);
wheelCenter_m = points_m(4, :);
end

function validateIdentity(identity)
try
    fsd.model.validateGeometryIdentity(identity);
catch cause
    exception = MException("fsd:kinematics:InvalidKinematicResult", ...
        "KinematicResult contains an invalid geometry identity.");
    exception = addCause(exception, cause);
    throwAsCaller(exception);
end
end

function value = comparisonTolerance(reference)
tolerances = fsd.model.numericTolerances();
value = 10 * (tolerances.AbsTol_m + ...
    tolerances.RelTol * max([abs(reference(:)); 1]));
end

function tf = isRealNumericSize(value, expectedSize)
tf = isnumeric(value) && isreal(value) && isequal(size(value), expectedSize);
end

function tf = isRealNumericScalar(value)
tf = isnumeric(value) && isreal(value) && isscalar(value);
end

function tf = isNonnegativeFiniteScalar(value)
tf = isRealNumericScalar(value) && isfinite(value) && value >= 0;
end

function tf = isTextScalar(value)
tf = (ischar(value) && isrow(value)) || ...
    (isstring(value) && isscalar(value) && ~ismissing(value));
end

function invalid(message, varargin)
error("fsd:kinematics:InvalidKinematicResult", message, varargin{:});
end
