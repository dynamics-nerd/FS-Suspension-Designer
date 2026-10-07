function residual_m = roadClosureResidual( ...
    bodyRollAngle_rad, leftContact_m, rightContact_m)
%ROADCLOSURERESIDUAL Return nRoad dot (Cright-Cleft) in chassis YZ.

frame = fsd.geometry.bodyRollRoadFrame(bodyRollAngle_rad);
leftContact_m = validateContact(leftContact_m, "leftContact_m");
rightContact_m = validateContact(rightContact_m, "rightContact_m");
residual_m = dot(frame.normal_yz, ...
    rightContact_m(2:3) - leftContact_m(2:3));
end

function point = validateContact(value, name)
if ~isnumeric(value) || ~isreal(value) || ...
        ~isequal(size(value), [1, 3]) || any(~isfinite(value))
    error("fsd:geometry:InvalidContact", ...
        "%s must be a finite real 1-by-3 point.", name);
end
point = double(value);
end
