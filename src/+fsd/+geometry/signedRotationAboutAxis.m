function angle_rad = signedRotationAboutAxis( ...
    axisPoint_m, axisDirection, vectorPointStatic_m, vectorPointCurrent_m)
%SIGNEDROTATIONABOUTAXIS Signed rotation of projected radial vectors.
%   The positive sense follows the right-hand rule about AXISDIRECTION.

inputs = {axisPoint_m, axisDirection, vectorPointStatic_m, ...
    vectorPointCurrent_m};
for index = 1:numel(inputs)
    value = inputs{index};
    if ~isnumeric(value) || ~isreal(value) || ...
            ~isequal(size(value), [1, 3]) || any(~isfinite(value))
        error("fsd:geometry:InvalidAxisRotationInput", ...
            "Axis-rotation inputs must be finite real 1-by-3 vectors.");
    end
end

axisNorm = norm(double(axisDirection), 2);
tolerances = fsd.model.numericTolerances();
if axisNorm <= tolerances.AbsTol_m
    error("fsd:geometry:DegenerateAxis", ...
        "axisDirection must be nonzero.");
end
unitAxis = double(axisDirection) ./ axisNorm;
staticOffset = double(vectorPointStatic_m) - double(axisPoint_m);
currentOffset = double(vectorPointCurrent_m) - double(axisPoint_m);
radialStatic = staticOffset - dot(unitAxis, staticOffset) .* unitAxis;
radialCurrent = currentOffset - dot(unitAxis, currentOffset) .* unitAxis;
scale_m = max([norm(staticOffset), norm(currentOffset), 1]);
threshold_m = tolerances.AbsTol_m + tolerances.RelTol * scale_m;
if norm(radialStatic) <= threshold_m || norm(radialCurrent) <= threshold_m
    error("fsd:geometry:DegenerateRadialVector", ...
        "Projected vectors must be nonzero to define a rotation.");
end
angle_rad = atan2(dot(unitAxis, cross(radialStatic, radialCurrent)), ...
    dot(radialStatic, radialCurrent));
end
