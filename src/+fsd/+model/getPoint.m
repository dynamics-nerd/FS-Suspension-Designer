function xyz_m = getPoint(geometry, pointId)
%GETPOINT Return one hardpoint position by canonical full ID.

fsd.model.validateDoubleWishboneGeometry(geometry);
if ~(ischar(pointId) || (isstring(pointId) && isscalar(pointId)))
    error("fsd:model:InvalidPointId", ...
        "pointId must be a text scalar.");
end
pointId = upper(strtrim(string(pointId)));
match = find(geometry.hardpoints.ids == pointId);
if isempty(match)
    error("fsd:model:PointNotFound", ...
        "Hardpoint ID not found: %s", pointId);
end
xyz_m = geometry.hardpoints.xyz_m(match, :);
end

