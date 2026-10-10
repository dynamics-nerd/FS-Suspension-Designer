function value = designText(value)
%DESIGNTEXT Stable case-sensitive IDs, independent of display names.
designRequire((ischar(value) && isrow(value)) || (isstring(value) && isscalar(value)),"Scalar text required.");
value = string(value);
designRequire(~ismissing(value) && ~isempty(regexp(value,'^[A-Z][A-Z0-9_]*$','once')),"Invalid stable ID.");
end
