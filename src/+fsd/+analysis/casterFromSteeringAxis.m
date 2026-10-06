function caster_rad = casterFromSteeringAxis(steeringAxis)
%CASTERFROMSTEERINGAXIS Return caster from the steering-axis XZ projection.
%   Positive caster means UBJ is displaced in +X (rearward) from LBJ.

steeringAxis = validateSteeringAxis(steeringAxis);
tolerances = fsd.model.numericTolerances();
if norm(steeringAxis([1, 3]), 2) <= tolerances.RelTol
    error("fsd:analysis:DegenerateCasterProjection", ...
        "Caster is undefined for a steering axis parallel to global Y.");
end
caster_rad = atan2(steeringAxis(1), steeringAxis(3));
end

function steeringAxis = validateSteeringAxis(value)
if ~isnumeric(value) || ~isreal(value) || ...
        ~isequal(size(value), [1, 3]) || any(~isfinite(value))
    error("fsd:analysis:InvalidSteeringAxis", ...
        "steeringAxis must be a finite real 1-by-3 vector.");
end
tolerances = fsd.model.numericTolerances();
axisNorm = norm(double(value), 2);
if axisNorm <= tolerances.RelTol
    error("fsd:analysis:DegenerateSteeringAxis", ...
        "steeringAxis must be nonzero.");
end
if abs(axisNorm - 1) > tolerances.AbsTol_m + tolerances.RelTol
    error("fsd:analysis:NonUnitSteeringAxis", ...
        "steeringAxis must be unit length.");
end
steeringAxis = double(value) ./ axisNorm;
end
