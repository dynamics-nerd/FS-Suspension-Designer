function rotationMatrix = rotationVectorToMatrix(rotationVector_rad)
%ROTATIONVECTORTOMATRIX Convert a 3-D rotation vector using Rodrigues.

if ~isnumeric(rotationVector_rad) || ~isreal(rotationVector_rad) || ...
        ~isequal(size(rotationVector_rad), [1, 3]) || ...
        any(~isfinite(rotationVector_rad))
    error("fsd:geometry:InvalidRotationVector", ...
        "rotationVector_rad must be a finite real 1-by-3 vector.");
end

rho = double(rotationVector_rad(:));
theta2 = dot(rho, rho);
theta = sqrt(theta2);
if theta < 1e-8
    theta4 = theta2 * theta2;
    coefficientA = 1 - theta2 / 6 + theta4 / 120;
    coefficientB = 0.5 - theta2 / 24 + theta4 / 720;
else
    coefficientA = sin(theta) / theta;
    coefficientB = (1 - cos(theta)) / theta2;
end

skewRho = [ ...
    0, -rho(3), rho(2); ...
    rho(3), 0, -rho(1); ...
    -rho(2), rho(1), 0];
rotationMatrix = eye(3) + coefficientA * skewRho + ...
    coefficientB * (skewRho * skewRho);
end

