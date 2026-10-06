function camber_rad = camberFromWheelAxis(wheelAxis, cornerId)
%CAMBERFROMWHEELAXIS Compute camber from an interior-to-exterior wheel axis.
%   This is the single canonical implementation of the camber equation.

if ~isnumeric(wheelAxis) || ~isreal(wheelAxis) || ...
        ~isequal(size(wheelAxis), [1, 3]) || any(~isfinite(wheelAxis))
    error("fsd:geometry:InvalidWheelAxis", ...
        "wheelAxis must be a finite real 1-by-3 vector.");
end
tolerances = fsd.model.numericTolerances();
axisNorm = norm(double(wheelAxis), 2);
if axisNorm <= tolerances.AbsTol_m
    error("fsd:geometry:InvalidWheelAxis", ...
        "wheelAxis must be nonzero.");
end
wheelAxis = double(wheelAxis) ./ axisNorm;

sideSign = cornerSideSign(cornerId);
outwardComponent = sideSign * wheelAxis(2);
if outwardComponent <= tolerances.RelTol
    error("fsd:geometry:InvalidWheelAxisOrientation", ...
        "wheelAxis must retain a positive lateral outward component.");
end
camber_rad = -atan2(wheelAxis(3), outwardComponent);
end

function sideSign = cornerSideSign(value)
isValidChar = ischar(value) && isrow(value);
isValidString = isstring(value) && isscalar(value) && ~ismissing(value);
if ~(isValidChar || isValidString)
    error("fsd:geometry:InvalidCorner", ...
        "Corner must be one of FL, FR, RL, or RR.");
end
cornerId = upper(strtrim(string(value)));
if ~ismember(cornerId, ["FL", "FR", "RL", "RR"])
    error("fsd:geometry:InvalidCorner", ...
        "Corner must be one of FL, FR, RL, or RR.");
end
sideSign = 1;
if ismember(cornerId, ["FL", "RL"])
    sideSign = -1;
end
end
