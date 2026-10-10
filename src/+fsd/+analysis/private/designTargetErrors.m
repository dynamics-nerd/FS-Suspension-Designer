function [deviation, violation] = designTargetErrors(t, y, value, lower, upper, tolerance)
%DESIGNTARGETERRORS Dimensional signed deviation and nonnegative excess outside acceptance.
switch t.type
    case {"POINT_TARGET","CURVE_TARGET"}
        deviation = y-value; violation = max(abs(deviation)-tolerance,0);
    case "UPPER_BOUND"
        deviation = y-upper; violation = max(deviation,0);
    case "LOWER_BOUND"
        deviation = y-lower; violation = max(-deviation,0);
    otherwise
        deviation = y-min(max(y,lower),upper);
        violation = max(max(lower-y,y-upper),0);
end
end
