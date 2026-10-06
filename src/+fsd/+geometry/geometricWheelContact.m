function contact = geometricWheelContact( ...
    wheelCenter_m, wheelAxis, radius_m)
%GEOMETRICWHEELCONTACT Lowest point of an ideal rigid circular wheel.

wheelCenter_m = validatePoint(wheelCenter_m);
if ~isnumeric(wheelAxis) || ~isreal(wheelAxis) || ...
        ~isequal(size(wheelAxis), [1, 3]) || any(~isfinite(wheelAxis))
    error("fsd:geometry:InvalidWheelAxis", ...
        "wheelAxis must be a finite real 1-by-3 vector.");
end
tolerances = fsd.model.numericTolerances();
axisNorm = norm(double(wheelAxis), 2);
if axisNorm <= tolerances.RelTol || ...
        abs(axisNorm - 1) > tolerances.AbsTol_m + tolerances.RelTol
    error("fsd:geometry:InvalidWheelAxis", ...
        "wheelAxis must be a unit vector.");
end
if ~isnumeric(radius_m) || ~isreal(radius_m) || ...
        ~isscalar(radius_m) || ~isfinite(radius_m) || radius_m <= 0
    error("fsd:geometry:InvalidWheelRadius", ...
        "radius_m must be a positive finite scalar.");
end
wheelAxis = double(wheelAxis) ./ axisNorm;
down = [0, 0, -1];
projectedDown = down - dot(down, wheelAxis) * wheelAxis;
projectionNorm = norm(projectedDown, 2);
if projectionNorm <= tolerances.RelTol
    contact = contactStruct("DEGENERATE", [NaN, NaN, NaN], ...
        "A near-vertical wheel axis has no unique lowest rim direction.");
    return
end
downInWheelPlane = projectedDown ./ projectionNorm;
point_m = wheelCenter_m + double(radius_m) * downInWheelPlane;
contact = contactStruct("FINITE", point_m, "");
end

function point_m = validatePoint(value)
if ~isnumeric(value) || ~isreal(value) || ...
        ~isequal(size(value), [1, 3]) || any(~isfinite(value))
    error("fsd:geometry:InvalidWheelCenter", ...
        "wheelCenter_m must be a finite real 1-by-3 point.");
end
point_m = double(value);
end

function contact = contactStruct(status, point_m, diagnostic)
contact = struct( ...
    "schemaVersion", "0.4.0", ...
    "kind", "GeometricWheelContact", ...
    "status", status, ...
    "point_m", point_m, ...
    "diagnostic", diagnostic);
end
