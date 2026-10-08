function rotationMatrix = rotationMatrixAboutAxis(axisDirection, angle_rad)
%ROTATIONMATRIXABOUTAXIS Proper rotation about an oriented 3-D axis.

if ~isnumeric(axisDirection) || ~isreal(axisDirection) || ...
        ~isequal(size(axisDirection), [1, 3]) || ...
        any(~isfinite(axisDirection))
    error("fsd:geometry:InvalidAxisDirection", ...
        "axisDirection must be a finite real 1-by-3 vector.");
end
if ~isnumeric(angle_rad) || ~isreal(angle_rad) || ...
        ~isscalar(angle_rad) || ~isfinite(angle_rad)
    error("fsd:geometry:InvalidAngle", ...
        "angle_rad must be a finite real scalar.");
end

axisNorm = norm(double(axisDirection), 2);
tolerances = fsd.model.numericTolerances();
if axisNorm <= tolerances.AbsTol_m
    error("fsd:geometry:DegenerateAxis", ...
        "axisDirection must be nonzero.");
end
unitAxis = double(axisDirection) ./ axisNorm;
rotationMatrix = fsd.geometry.rotationVectorToMatrix( ...
    unitAxis .* double(angle_rad));
end
