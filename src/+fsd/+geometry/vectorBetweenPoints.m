function vector_m = vectorBetweenPoints(geometry, fromPointId, toPointId)
%VECTORBETWEENPOINTS Vector from one hardpoint to another, in metres.

fromPoint_m = fsd.model.getPoint(geometry, fromPointId);
toPoint_m = fsd.model.getPoint(geometry, toPointId);
vector_m = toPoint_m - fromPoint_m;
end

