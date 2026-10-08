function value = mechanicalBounds(model, length, seats)
%MECHANICALBOUNDS No end-stop or coil-bind constitutive extension.
value = struct("damperTravelStatus","UNKNOWN","springSolidStatus","UNKNOWN", ...
    "damperMinimumMargin_m",NaN,"damperMaximumMargin_m",NaN, ...
    "springSolidMargin_m",NaN,"feasibleRelativeToProvidedLimits",true);
tol = 64*eps(max([abs(length),abs(seats),model.spring.freeLength_m,1]));
d = model.damper;
if ~isempty(d.minimumLength_m) || ~isempty(d.maximumLength_m)
    value.damperTravelStatus = "WITHIN_PROVIDED_LIMITS";
end
if ~isempty(d.minimumLength_m)
    value.damperMinimumMargin_m = length-d.minimumLength_m;
end
if ~isempty(d.maximumLength_m)
    value.damperMaximumMargin_m = d.maximumLength_m-length;
end
if value.damperMinimumMargin_m < -tol || value.damperMaximumMargin_m < -tol
    value.damperTravelStatus = "DAMPER_TRAVEL_LIMIT_EXCEEDED";
    value.feasibleRelativeToProvidedLimits = false;
end
if ~isempty(model.spring.solidHeight_m)
    margin = seats-model.spring.solidHeight_m;
    value.springSolidMargin_m = margin;
    if margin < -tol
        value.springSolidStatus = "COIL_BIND_EXCEEDED";
        value.feasibleRelativeToProvidedLimits = false;
    elseif abs(margin) <= tol
        value.springSolidStatus = "COIL_BIND_LIMIT";
    else
        value.springSolidStatus = "ABOVE_PROVIDED_SOLID_HEIGHT";
    end
end
if seats <= 0
    value.springSolidStatus = "INVALID_SPRING_SEAT_GEOMETRY";
    value.feasibleRelativeToProvidedLimits = false;
end
end
