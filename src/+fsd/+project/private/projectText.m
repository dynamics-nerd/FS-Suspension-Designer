function value = projectText(value,allowEmpty)
%PROJECTTEXT Scalar text only; never evaluate user strings.
if nargin<2, allowEmpty=false; end
projectRequire((ischar(value) && (isrow(value) || isempty(value))) || ...
    (isstring(value) && isscalar(value) && ~ismissing(value)),'Scalar text required.');
value=string(value);
projectRequire(allowEmpty || strlength(value)>0,'Nonempty text required.');
end
