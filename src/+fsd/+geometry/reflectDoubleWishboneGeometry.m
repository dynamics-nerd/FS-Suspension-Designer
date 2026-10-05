function reflected = reflectDoubleWishboneGeometry(geometry)
%REFLECTDOUBLEWISHBONEGEOMETRY Reflect a corner about the vehicle Y=0 plane.
%   FL <-> FR and RL <-> RR. The input struct is not modified.

fsd.model.validateDoubleWishboneGeometry(geometry);
oldCorner = geometry.cornerId;
switch oldCorner
    case "FL"
        newCorner = "FR";
    case "FR"
        newCorner = "FL";
    case "RL"
        newCorner = "RR";
    case "RR"
        newCorner = "RL";
    otherwise
        error("fsd:model:InvalidCorner", "Unsupported corner ID.");
end

reflected = geometry;
reflected.cornerId = newCorner;
reflected.hardpoints.xyz_m(:, 2) = -reflected.hardpoints.xyz_m(:, 2);
reflected.hardpoints.ids = replaceCornerPrefix( ...
    reflected.hardpoints.ids, oldCorner, newCorner);
reflected.connectivity.pointIds = replaceCornerPrefix( ...
    reflected.connectivity.pointIds, oldCorner, newCorner);
reflected.upright.pointIds = replaceCornerPrefix( ...
    reflected.upright.pointIds, oldCorner, newCorner);
reflected.wheel.centerId = replaceCornerPrefix( ...
    string(reflected.wheel.centerId), oldCorner, newCorner);
reflected.wheel.contactPatchId = replaceCornerPrefix( ...
    string(reflected.wheel.contactPatchId), oldCorner, newCorner);
reflected.wheel.wheelAxis(2) = -reflected.wheel.wheelAxis(2);

fsd.model.validateDoubleWishboneGeometry(reflected);
end

function values = replaceCornerPrefix(values, oldCorner, newCorner)
values = string(values);
oldPrefix = oldCorner + "_";
newPrefix = newCorner + "_";
if any(~startsWith(values, oldPrefix), "all")
    error("fsd:model:CornerPrefixMismatch", ...
        "Cannot reflect IDs with an inconsistent corner prefix.");
end
values = newPrefix + extractAfter(values, strlength(oldPrefix));
end

