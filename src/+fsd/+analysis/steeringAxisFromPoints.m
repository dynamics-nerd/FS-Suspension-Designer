function steeringAxis = steeringAxisFromPoints(lbj_m, ubj_m)
%STEERINGAXISFROMPOINTS Return the unit steering axis from LBJ to UBJ.

lbj_m = validatePoint(lbj_m, "lbj_m");
ubj_m = validatePoint(ubj_m, "ubj_m");
axisVector_m = ubj_m - lbj_m;
tolerances = fsd.model.numericTolerances();
scale_m = max([norm(lbj_m, 2), norm(ubj_m, 2), 1]);
if norm(axisVector_m, 2) <= ...
        tolerances.AbsTol_m + tolerances.RelTol * scale_m
    error("fsd:analysis:DegenerateSteeringAxis", ...
        "LBJ and UBJ must not be coincident.");
end
steeringAxis = axisVector_m ./ norm(axisVector_m, 2);
end

function point_m = validatePoint(value, name)
if ~isnumeric(value) || ~isreal(value) || ...
        ~isequal(size(value), [1, 3]) || any(~isfinite(value))
    error("fsd:analysis:InvalidPoint", ...
        "%s must be a finite real 1-by-3 vector in metres.", name);
end
point_m = double(value);
end
