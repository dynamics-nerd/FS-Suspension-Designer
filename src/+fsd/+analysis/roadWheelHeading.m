function [heading, angle_rad] = roadWheelHeading(wheelAxis, cornerId)
%ROADWHEELHEADING Return horizontal forward heading and signed angle.
%   Positive angle points toward +Y (right turn); straight is [-1,0,0].

if ~isnumeric(wheelAxis) || ~isreal(wheelAxis) || ...
        ~isequal(size(wheelAxis), [1, 3]) || any(~isfinite(wheelAxis))
    error("fsd:analysis:InvalidWheelAxis", ...
        "wheelAxis must be a finite real 1-by-3 vector.");
end
axisNorm = norm(double(wheelAxis));
tolerances = fsd.model.numericTolerances();
if abs(axisNorm - 1) > tolerances.AbsTol_m + tolerances.RelTol
    error("fsd:analysis:NonUnitWheelAxis", ...
        "wheelAxis must be unit length.");
end
cornerId = upper(strtrim(string(cornerId)));
if ~isscalar(cornerId) || ~ismember(cornerId, ["FL", "FR"])
    error("fsd:analysis:InvalidCorner", ...
        "Road-wheel heading is defined for FL or FR.");
end
sideSign = 1;
if cornerId == "FL"
    sideSign = -1;
end
horizontalAxis = double(wheelAxis(1:2));
horizontalNorm = norm(horizontalAxis);
if horizontalNorm <= tolerances.RelTol
    error("fsd:analysis:DegenerateWheelHeading", ...
        "A vertical wheel axis has no horizontal road-wheel heading.");
end
horizontalAxis = horizontalAxis ./ horizontalNorm;
heading = sideSign * [-horizontalAxis(2), horizontalAxis(1), 0];
if heading(1) >= -tolerances.RelTol
    error("fsd:analysis:InvalidWheelAxisOrientation", ...
        "wheelAxis does not define a forward-facing wheel heading.");
end
angle_rad = atan2(heading(2), -heading(1));
end
