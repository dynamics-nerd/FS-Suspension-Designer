function [cornerId, sideSign] = normalizeCornerId(value)
%NORMALIZECORNERID Validate one semantic corner text scalar.

isValidChar = ischar(value) && isrow(value);
isValidString = isstring(value) && isscalar(value) && ~ismissing(value);
if ~(isValidChar || isValidString)
    error("fsd:analysis:InvalidCorner", ...
        "Corner must be one of FL, FR, RL, or RR.");
end
cornerId = upper(strtrim(string(value)));
if ~ismember(cornerId, ["FL", "FR", "RL", "RR"])
    error("fsd:analysis:InvalidCorner", ...
        "Corner must be one of FL, FR, RL, or RR.");
end
sideSign = 1;
if ismember(cornerId, ["FL", "RL"])
    sideSign = -1;
end
end
