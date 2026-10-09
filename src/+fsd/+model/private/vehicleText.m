function value = vehicleText(value)
%VEHICLETEXT Nonempty scalar text, never a char matrix or missing string.
vehicleRequire((isstring(value) && isscalar(value) && ~ismissing(value)) || ...
    (ischar(value) && isrow(value)),"Expected scalar text.");
value = string(value);
vehicleRequire(strlength(value) > 0,"Text cannot be empty.");
end
