function distance_m = distanceBetweenPoints(geometry, pointIdA, pointIdB)
%DISTANCEBETWEENPOINTS Euclidean distance between hardpoints, in metres.

vector_m = fsd.geometry.vectorBetweenPoints(geometry, pointIdA, pointIdB);
distance_m = norm(vector_m, 2);
end

