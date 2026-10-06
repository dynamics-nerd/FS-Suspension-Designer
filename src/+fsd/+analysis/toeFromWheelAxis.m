function toe_rad = toeFromWheelAxis(wheelAxis, cornerId)
%TOEFROMWHEELAXIS Return side-independent toe in radians.
%   Positive is toe-in and negative is toe-out. The vertical component of
%   wheelAxis is excluded by using its XY projection.

[wheelAxis, sideSign] = validateInputs(wheelAxis, cornerId);
outwardComponent = sideSign * wheelAxis(2);
toe_rad = atan2(-wheelAxis(1), outwardComponent);
end

function [wheelAxis, sideSign] = validateInputs(wheelAxis, cornerId)
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

if ~(ischar(cornerId) || (isstring(cornerId) && isscalar(cornerId)))
    error("fsd:analysis:InvalidCorner", ...
        "Corner must be one of FL, FR, RL, or RR.");
end
cornerId = upper(strtrim(string(cornerId)));
if ~ismember(cornerId, ["FL", "FR", "RL", "RR"])
    error("fsd:analysis:InvalidCorner", ...
        "Corner must be one of FL, FR, RL, or RR.");
end
sideSign = 1;
if ismember(cornerId, ["FL", "RL"])
    sideSign = -1;
end

horizontalNorm = norm(wheelAxis(1:2), 2);
outwardComponent = sideSign * wheelAxis(2);
if horizontalNorm <= tolerances.RelTol
    error("fsd:analysis:DegenerateToeProjection", ...
        "Toe is undefined for a wheel axis with a degenerate XY projection.");
end
if outwardComponent <= tolerances.RelTol
    error("fsd:analysis:InvalidWheelAxisOrientation", ...
        "wheelAxis must retain a positive lateral outward component.");
end
end
