function intersection = intersectSteeringAxisWithHorizontalPlane( ...
    lbj_m, ubj_m, planeZ_m)
%INTERSECTSTEERINGAXISWITHHORIZONTALPLANE Intersect LBJ-UBJ with Z=constant.

lbj_m = validatePoint(lbj_m, "lbj_m");
ubj_m = validatePoint(ubj_m, "ubj_m");
if ~isnumeric(planeZ_m) || ~isreal(planeZ_m) || ...
        ~isscalar(planeZ_m) || ~isfinite(planeZ_m)
    error("fsd:geometry:InvalidPlaneZ", ...
        "planeZ_m must be a finite real scalar in metres.");
end
axisVector_m = ubj_m - lbj_m;
axisLength_m = norm(axisVector_m);
tolerances = fsd.model.numericTolerances();
scale_m = max([norm(lbj_m), norm(ubj_m), 1]);
if axisLength_m <= tolerances.AbsTol_m + tolerances.RelTol * scale_m
    intersection = result("DEGENERATE", [NaN, NaN, NaN], ...
        NaN, false, "LBJ and UBJ do not define a steering axis.");
    return
end
axisDirection = axisVector_m ./ axisLength_m;
conditioning = abs(axisDirection(3));
parallelTolerance = 100 * eps;
if conditioning <= parallelTolerance
    intersection = result("PARALLEL", [NaN, NaN, NaN], ...
        conditioning, false, ...
        "The steering axis is parallel to the horizontal plane.");
    return
end
parameter_m = (double(planeZ_m) - lbj_m(3)) / axisDirection(3);
point_m = lbj_m + parameter_m * axisDirection;
illConditioned = conditioning <= sqrt(eps);
diagnostic = "";
if illConditioned
    diagnostic = "The finite steering-axis intersection is ill-conditioned.";
end
intersection = result("FINITE", point_m, conditioning, ...
    illConditioned, diagnostic);
end

function point_m = validatePoint(value, name)
if ~isnumeric(value) || ~isreal(value) || ...
        ~isequal(size(value), [1, 3]) || any(~isfinite(value))
    error("fsd:geometry:InvalidPoint", ...
        "%s must be a finite real 1-by-3 point.", name);
end
point_m = double(value);
end

function value = result(status, point_m, conditioning, ill, diagnostic)
value = struct( ...
    "schemaVersion", "0.5.0", ...
    "kind", "SteeringAxisHorizontalPlaneIntersection", ...
    "status", status, ...
    "point_m", point_m, ...
    "conditioning", conditioning, ...
    "isIllConditioned", logical(ill), ...
    "diagnostic", diagnostic);
end
