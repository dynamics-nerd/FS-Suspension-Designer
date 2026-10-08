function validateActuationSource(result)
%VALIDATEACTUATIONSOURCE Validate a corner result consumed by actuation.

if ~isstruct(result) || ~isscalar(result) || ~isfield(result, "kind")
    invalid("Source result must be a scalar corner-result struct.");
end
kind = string(result.kind);
if kind == "KinematicResult"
    try
        fsd.kinematics.validateKinematicResult(result);
    catch cause
        exception = MException("fsd:kinematics:InvalidActuationSource", ...
            "Source KinematicResult is invalid.");
        exception = addCause(exception, cause);
        throwAsCaller(exception);
    end
elseif kind == "SteeringCornerResult"
    try
        fsd.kinematics.validateSteeringCornerResult(result);
    catch cause
        exception = MException("fsd:kinematics:InvalidActuationSource", ...
            "Source SteeringCornerResult is invalid.");
        exception = addCause(exception, cause);
        throwAsCaller(exception);
    end
else
    invalid("Source must be KinematicResult or SteeringCornerResult.");
end
end

function invalid(message, varargin)
error("fsd:kinematics:InvalidActuationSource", message, varargin{:});
end
