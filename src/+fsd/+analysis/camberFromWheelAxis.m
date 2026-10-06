function camber_rad = camberFromWheelAxis(wheelAxis, cornerId)
%CAMBERFROMWHEELAXIS Return side-independent camber in radians.
%   Negative camber means the wheel top leans toward vehicle center.

[wheelAxis, sideSign] = validateWheelAxis(wheelAxis, cornerId);
outwardComponent = sideSign * wheelAxis(2);
camber_rad = -atan2(wheelAxis(3), outwardComponent);
end

function [wheelAxis, sideSign] = validateWheelAxis(wheelAxis, cornerId)
if ~isnumeric(wheelAxis) || ~isreal(wheelAxis) || ...
        ~isequal(size(wheelAxis), [1, 3]) || any(~isfinite(wheelAxis))
    error("fsd:analysis:InvalidWheelAxis", ...
        "wheelAxis must be a finite real 1-by-3 vector.");
end
tolerances = fsd.model.numericTolerances();
axisNorm = norm(double(wheelAxis), 2);
if axisNorm <= tolerances.AbsTol_m
    error("fsd:analysis:DegenerateWheelAxis", ...
        "wheelAxis must be nonzero.");
end
if abs(axisNorm - 1) > tolerances.AbsTol_m + tolerances.RelTol
    error("fsd:analysis:NonUnitWheelAxis", ...
        "wheelAxis must be unit length.");
end
wheelAxis = double(wheelAxis) ./ axisNorm;

[cornerId, sideSign] = normalizeCorner(cornerId); %#ok<ASGLU>
outwardComponent = sideSign * wheelAxis(2);
if outwardComponent <= tolerances.RelTol
    error("fsd:analysis:InvalidWheelAxisOrientation", ...
        "wheelAxis must retain a positive lateral outward component.");
end
end

function [cornerId, sideSign] = normalizeCorner(value)
if ~(ischar(value) || (isstring(value) && isscalar(value)))
    error("fsd:analysis:InvalidCorner", ...
        "Corner must be one of FL, FR, RL, or RR.");
end
cornerId = upper(strtrim(string(value)));
if ~ismember(cornerId, ["FL", "FR", "RL", "RR"])
    error("fsd:analysis:InvalidCorner", ...
        "Corner must be one of FL, FR, RL, or RR.");
end
sideSign = 1;
if ismember(cornerId, ["FL", "RL"])
    sideSign = -1;
end
end
