function value_rad = convertAngleToRadians(value, inputUnit)
%CONVERTANGLETORADIANS Convert finite real angles to SI radians.

if ~isnumeric(value) || ~isreal(value) || any(~isfinite(value), "all")
    error("fsd:model:InvalidAngleValue", ...
        "Angle input must contain only finite real numeric values.");
end
if ~(ischar(inputUnit) || (isstring(inputUnit) && isscalar(inputUnit)))
    error("fsd:model:InvalidAngleUnit", ...
        "Input angle unit must be 'rad' or 'deg'.");
end
switch lower(strtrim(string(inputUnit)))
    case "rad"
        scale = 1;
    case "deg"
        scale = pi / 180;
    otherwise
        error("fsd:model:InvalidAngleUnit", ...
            "Input angle unit must be 'rad' or 'deg'.");
end
value_rad = double(value) .* scale;
end
