function q = globalCoordinateInput(q)
%GLOBALCOORDINATEINPUT Seven coordinates, m/rad/rad/m/m/m/m in a column.
if ~isnumeric(q) || ~isreal(q) || ~isequal(size(q),[7,1]) || any(~isfinite(q)) || ...
        any(abs(q(2:3)) >= pi/2)
    error("fsd:analysis:InvalidGlobalStaticInput","Finite SI 7-by-1 q with upright angle chart required.");
end
q = double(q);
end
