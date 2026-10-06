function camber_rad = camberFromWheelAxis(wheelAxis, cornerId)
%CAMBERFROMWHEELAXIS Return side-independent camber in radians.
%   Negative camber means the wheel top leans toward vehicle center.

[wheelAxis, cornerId] = validateWheelAxis(wheelAxis, cornerId);
camber_rad = fsd.geometry.camberFromWheelAxis(wheelAxis, cornerId);
end

function [wheelAxis, cornerId] = validateWheelAxis(wheelAxis, cornerId)
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

[cornerId, sideSign] = normalizeCornerId(cornerId);
outwardComponent = sideSign * wheelAxis(2);
if outwardComponent <= tolerances.RelTol
    error("fsd:analysis:InvalidWheelAxisOrientation", ...
        "wheelAxis must retain a positive lateral outward component.");
end
end
