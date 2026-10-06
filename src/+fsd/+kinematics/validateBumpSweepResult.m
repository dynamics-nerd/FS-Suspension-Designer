function isValid = validateBumpSweepResult(sweep)
%VALIDATEBUMPSWEEPRESULT Validate a complete geometry-bound bump sweep.

if ~isstruct(sweep) || ~isscalar(sweep)
    invalid("BumpSweepResult must be a scalar struct.");
end
required = ["schemaVersion", "kind", "geometryIdentity", ...
    "requestedWheelTravel_m", "achievedWheelTravel_m", "camber_rad", ...
    "converged", "allConverged", "elapsedTime_s", "results"];
for index = 1:numel(required)
    if ~isfield(sweep, required(index))
        invalid("BumpSweepResult is missing field '%s'.", required(index));
    end
end
if ~isTextScalar(sweep.schemaVersion) || ...
        string(sweep.schemaVersion) ~= "0.3.0" || ...
        ~isTextScalar(sweep.kind) || string(sweep.kind) ~= "BumpSweepResult"
    invalid("Unsupported or invalid BumpSweepResult schema.");
end
validateIdentity(sweep.geometryIdentity);

count = numel(sweep.requestedWheelTravel_m);
if ~isnumeric(sweep.requestedWheelTravel_m) || ...
        ~isreal(sweep.requestedWheelTravel_m) || ...
        ~iscolumn(sweep.requestedWheelTravel_m) || count == 0 || ...
        any(~isfinite(sweep.requestedWheelTravel_m)) || ...
        ~isRealNumericColumn(sweep.achievedWheelTravel_m, count) || ...
        ~isRealNumericColumn(sweep.camber_rad, count) || ...
        ~islogical(sweep.converged) || ...
        ~isequal(size(sweep.converged), [count, 1]) || ...
        ~islogical(sweep.allConverged) || ~isscalar(sweep.allConverged) || ...
        ~isnumeric(sweep.elapsedTime_s) || ~isreal(sweep.elapsedTime_s) || ...
        ~isscalar(sweep.elapsedTime_s) || ~isfinite(sweep.elapsedTime_s) || ...
        sweep.elapsedTime_s < 0 || ~isstruct(sweep.results) || ...
        ~iscolumn(sweep.results) || numel(sweep.results) ~= count
    invalid("BumpSweepResult fields have invalid types or dimensions.");
end

for index = 1:count
    try
        fsd.kinematics.validateKinematicResult(sweep.results(index));
    catch cause
        exception = MException("fsd:kinematics:InvalidBumpSweepResult", ...
            "BumpSweepResult contains invalid result %d.", index);
        exception = addCause(exception, cause);
        throwAsCaller(exception);
    end
    if ~isequal(sweep.results(index).geometryIdentity, ...
            sweep.geometryIdentity)
        invalid("Result %d belongs to a different geometry identity.", index);
    end
end

resultRequested_m = reshape( ...
    [sweep.results.requestedWheelTravel_m], [], 1);
resultAchieved_m = reshape( ...
    [sweep.results.achievedWheelTravel_m], [], 1);
resultCamber_rad = reshape([sweep.results.camber_rad], [], 1);
resultConverged = reshape([sweep.results.converged], [], 1);
if ~isequal(sweep.requestedWheelTravel_m, resultRequested_m) || ...
        ~isequaln(sweep.achievedWheelTravel_m, resultAchieved_m) || ...
        ~isequaln(sweep.camber_rad, resultCamber_rad) || ...
        ~isequal(sweep.converged, resultConverged) || ...
        sweep.allConverged ~= all(resultConverged)
    invalid("BumpSweepResult aggregate fields contradict contained results.");
end
isValid = true;
end

function validateIdentity(identity)
try
    fsd.model.validateGeometryIdentity(identity);
catch cause
    exception = MException("fsd:kinematics:InvalidBumpSweepResult", ...
        "BumpSweepResult contains an invalid geometry identity.");
    exception = addCause(exception, cause);
    throwAsCaller(exception);
end
end

function tf = isRealNumericColumn(value, count)
tf = isnumeric(value) && isreal(value) && ...
    isequal(size(value), [count, 1]);
end

function tf = isTextScalar(value)
tf = (ischar(value) && isrow(value)) || ...
    (isstring(value) && isscalar(value) && ~ismissing(value));
end

function invalid(message, varargin)
error("fsd:kinematics:InvalidBumpSweepResult", message, varargin{:});
end
