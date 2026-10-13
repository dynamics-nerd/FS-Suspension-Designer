function u = normalizeSteeringVariables(space,x_m)
%NORMALIZESTEERINGVARIABLES Independent physical coordinates to the closed unit box.
fsd.synthesis.validateSteeringDesignSpace(space);
u=coordinateCore(space,x_m,"NORMALIZE");
end
