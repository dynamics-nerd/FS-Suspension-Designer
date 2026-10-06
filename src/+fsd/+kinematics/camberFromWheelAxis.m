function camber_rad = camberFromWheelAxis(wheelAxis, cornerId)
%CAMBERFROMWHEELAXIS Return side-independent camber in radians.
%   Negative camber means the wheel top leans toward vehicle center.

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
cornerId = upper(strtrim(string(cornerId)));
if ~isscalar(cornerId) || ~ismember(cornerId, ["FL", "FR", "RL", "RR"])
    error("fsd:model:InvalidCorner", ...
        "Corner must be one of FL, FR, RL, or RR.");
end

sideSign = 1;
if ismember(cornerId, ["FL", "RL"])
    sideSign = -1;
end
outwardComponent = sideSign * wheelAxis(2);
if outwardComponent <= tolerances.RelTol
    error("fsd:kinematics:InvalidWheelAxisOrientation", ...
        "wheelAxis must retain a positive lateral outward component.");
end
camber_rad = -atan2(wheelAxis(3), outwardComponent);
end

