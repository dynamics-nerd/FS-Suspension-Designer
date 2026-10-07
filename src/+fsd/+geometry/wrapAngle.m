function angle_rad = wrapAngle(angle_rad)
%WRAPANGLE Wrap real angles to [-pi,pi] using atan2.

if ~isnumeric(angle_rad) || ~isreal(angle_rad) || any(~isfinite(angle_rad), "all")
    error("fsd:geometry:InvalidAngle", ...
        "angle_rad must contain finite real numeric values.");
end
angle_rad = atan2(sin(double(angle_rad)), cos(double(angle_rad)));
end
