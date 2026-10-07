function rotationMatrix = rotationMatrixX(angle_rad)
%ROTATIONMATRIXX Return a right-handed rotation about global +X.

if ~isnumeric(angle_rad) || ~isreal(angle_rad) || ...
        ~isscalar(angle_rad) || ~isfinite(angle_rad)
    error("fsd:geometry:InvalidAngle", ...
        "angle_rad must be a finite real scalar.");
end
c = cos(double(angle_rad));
s = sin(double(angle_rad));
rotationMatrix = [1, 0, 0; 0, c, -s; 0, s, c];
end
