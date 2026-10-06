function value_m = convertLengthToMetres(value, inputUnit)
%CONVERTLENGTHTOMETRES Convert finite real length values to SI metres.

if ~isnumeric(value) || ~isreal(value)
    error("fsd:model:InvalidLengthValue", ...
        "Length input must be real and numeric.");
end
if any(~isfinite(value), "all")
    error("fsd:model:NonFiniteLength", ...
        "Length input must contain only finite values.");
end
if ~(ischar(inputUnit) || (isstring(inputUnit) && isscalar(inputUnit)))
    error("fsd:model:InvalidInputUnit", ...
        "Input length unit must be 'm' or 'mm'.");
end
unit = lower(strtrim(string(inputUnit)));
switch unit
    case "m"
        scale = 1;
    case "mm"
        scale = 1e-3;
    otherwise
        error("fsd:model:InvalidInputUnit", ...
            "Input length unit must be 'm' or 'mm'.");
end
value_m = double(value) .* scale;
end
