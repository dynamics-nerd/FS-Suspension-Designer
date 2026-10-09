function value = vehicleValue(value, count, unknownAllowed)
%VEHICLEVALUE Canonical numeric row; NaN denotes explicit unavailability.
vehicleRequire(isnumeric(value) && isreal(value) && isvector(value) && ...
    numel(value) == count,"Invalid numeric dimensions.");
value = reshape(double(value),1,[]);
vehicleRequire(~any(isinf(value)) && (unknownAllowed || all(isfinite(value))), ...
    "Invalid nonfinite input.");
end
