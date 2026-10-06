function camber_rad = camberFromWheelAxis(wheelAxis, cornerId)
%CAMBERFROMWHEELAXIS Return side-independent camber in radians.
%   Compatibility wrapper retained for the public v0.2 API. New code may
%   call fsd.analysis.camberFromWheelAxis directly.

if ~isnumeric(wheelAxis) || ~isreal(wheelAxis) || ...
        ~isequal(size(wheelAxis), [1, 3]) || any(~isfinite(wheelAxis))
    error("fsd:kinematics:InvalidWheelAxis", ...
        "wheelAxis must be a finite real 1-by-3 vector.");
end
axisNorm = norm(double(wheelAxis), 2);
tolerances = fsd.model.numericTolerances();
if axisNorm <= tolerances.AbsTol_m
    error("fsd:kinematics:InvalidWheelAxis", ...
        "wheelAxis must be nonzero.");
end
wheelAxis = double(wheelAxis) ./ axisNorm;

try
    camber_rad = fsd.analysis.camberFromWheelAxis(wheelAxis, cornerId);
catch cause
    switch cause.identifier
        case {"fsd:analysis:InvalidWheelAxis", ...
                "fsd:analysis:DegenerateWheelAxis"}
            error("fsd:kinematics:InvalidWheelAxis", "%s", cause.message);
        case "fsd:analysis:InvalidWheelAxisOrientation"
            error("fsd:kinematics:InvalidWheelAxisOrientation", ...
                "%s", cause.message);
        case "fsd:analysis:InvalidCorner"
            error("fsd:model:InvalidCorner", "%s", cause.message);
        otherwise
            rethrow(cause)
    end
end
end
