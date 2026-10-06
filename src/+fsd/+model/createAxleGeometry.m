function axle = createAxleGeometry(leftGeometry, rightGeometry)
%CREATEAXLEGEOMETRY Compose canonical left and right corner geometries.

fsd.model.validateDoubleWishboneGeometry(leftGeometry);
fsd.model.validateDoubleWishboneGeometry(rightGeometry);

leftCorner = string(leftGeometry.cornerId);
rightCorner = string(rightGeometry.cornerId);
if leftCorner == "FL" && rightCorner == "FR"
    axleId = "FRONT";
elseif leftCorner == "RL" && rightCorner == "RR"
    axleId = "REAR";
else
    error("fsd:model:InvalidAxleCorners", ...
        "Axle corners must be ordered FL/FR or RL/RR.");
end

axle = struct( ...
    "schemaVersion", "0.4.0", ...
    "kind", "AxleGeometry", ...
    "axleId", axleId, ...
    "leftGeometry", leftGeometry, ...
    "rightGeometry", rightGeometry);
fsd.model.validateAxleGeometry(axle);
end
