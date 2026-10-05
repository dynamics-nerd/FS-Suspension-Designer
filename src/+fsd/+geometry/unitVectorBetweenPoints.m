function unitVector = unitVectorBetweenPoints(geometry, fromPointId, toPointId)
%UNITVECTORBETWEENPOINTS Unit vector from one hardpoint to another.

vector_m = fsd.geometry.vectorBetweenPoints( ...
    geometry, fromPointId, toPointId);
vectorNorm_m = norm(vector_m, 2);
tolerances = fsd.model.numericTolerances();
if vectorNorm_m <= tolerances.AbsTol_m
    error("fsd:geometry:CoincidentPoints", ...
        "A unit vector is undefined for coincident points.");
end
unitVector = vector_m ./ vectorNorm_m;
end

