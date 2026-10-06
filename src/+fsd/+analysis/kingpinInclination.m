function kingpinInclination_rad = kingpinInclination( ...
    steeringAxis, cornerId)
%KINGPININCLINATION Return side-independent KPI from the YZ projection.
%   Positive means the upper end of the steering axis leans toward the
%   vehicle centerline. The canonical output name is kingpinInclination.

[steeringAxis, sideSign] = validateInputs(steeringAxis, cornerId);
tolerances = fsd.model.numericTolerances();
if norm(steeringAxis([2, 3]), 2) <= tolerances.RelTol
    error("fsd:analysis:DegenerateKingpinProjection", ...
        "Kingpin inclination is undefined for an axis parallel to global X.");
end
inwardComponent = -sideSign * steeringAxis(2);
kingpinInclination_rad = atan2(inwardComponent, steeringAxis(3));
end

function [steeringAxis, sideSign] = validateInputs(value, cornerId)
if ~isnumeric(value) || ~isreal(value) || ...
        ~isequal(size(value), [1, 3]) || any(~isfinite(value))
    error("fsd:analysis:InvalidSteeringAxis", ...
        "steeringAxis must be a finite real 1-by-3 vector.");
end
tolerances = fsd.model.numericTolerances();
axisNorm = norm(double(value), 2);
if axisNorm <= tolerances.RelTol
    error("fsd:analysis:DegenerateSteeringAxis", ...
        "steeringAxis must be nonzero.");
end
if abs(axisNorm - 1) > tolerances.AbsTol_m + tolerances.RelTol
    error("fsd:analysis:NonUnitSteeringAxis", ...
        "steeringAxis must be unit length.");
end
steeringAxis = double(value) ./ axisNorm;

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
end
