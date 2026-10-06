function camber_rad = camberFromWheelAxis(wheelAxis, cornerId)
%CAMBERFROMWHEELAXIS Return side-independent camber in radians.
%   Compatibility wrapper retained for the public v0.2 API. The canonical
%   equation is implemented by fsd.geometry.camberFromWheelAxis.

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
    camber_rad = fsd.geometry.camberFromWheelAxis(wheelAxis, cornerId);
catch cause
    switch cause.identifier
        case "fsd:geometry:InvalidWheelAxis"
            error("fsd:kinematics:InvalidWheelAxis", "%s", cause.message);
        case "fsd:geometry:InvalidWheelAxisOrientation"
            error("fsd:kinematics:InvalidWheelAxisOrientation", ...
                "%s", cause.message);
        case "fsd:geometry:InvalidCorner"
            error("fsd:model:InvalidCorner", "%s", cause.message);
        otherwise
            rethrow(cause)
    end
end
end
