function settings = solverSettings(overrides)
%SOLVERSETTINGS Central numerical settings for v0.2 bump kinematics.

settings = struct( ...
    "MaxContinuationStep_m", 0.005, ...
    "FunctionTolerance", 1e-12, ...
    "StepTolerance", 1e-12, ...
    "OptimalityTolerance", 1e-12, ...
    "MaxIterations", 200, ...
    "MaxFunctionEvaluations", 2000);

if nargin < 1 || isempty(overrides)
    return
end
if ~isstruct(overrides) || ~isscalar(overrides)
    error("fsd:kinematics:InvalidOptions", ...
        "Solver options must be a scalar struct.");
end
allowedFields = string(fieldnames(settings));
requestedFields = string(fieldnames(overrides));
unknownFields = requestedFields(~ismember(requestedFields, allowedFields));
if ~isempty(unknownFields)
    error("fsd:kinematics:InvalidOptions", ...
        "Unknown solver option: %s", unknownFields(1));
end
for index = 1:numel(requestedFields)
    name = requestedFields(index);
    settings.(name) = overrides.(name);
end

positiveScalarFields = [ ...
    "MaxContinuationStep_m", "FunctionTolerance", "StepTolerance", ...
    "OptimalityTolerance", "MaxIterations", "MaxFunctionEvaluations"];
for index = 1:numel(positiveScalarFields)
    name = positiveScalarFields(index);
    value = settings.(name);
    if ~isnumeric(value) || ~isreal(value) || ~isscalar(value) || ...
            ~isfinite(value) || value <= 0
        error("fsd:kinematics:InvalidOptions", ...
            "%s must be a positive finite scalar.", name);
    end
end
settings.MaxIterations = floor(settings.MaxIterations);
settings.MaxFunctionEvaluations = floor(settings.MaxFunctionEvaluations);
end

