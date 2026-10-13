function x_m = denormalizeSteeringVariables(space,u)
%DENORMALIZESTEERINGVARIABLES Reuse v0.12 endpoint, seed and frozen-axis policy.
fsd.synthesis.validateSteeringDesignSpace(space);
x_m=coordinateCore(space,u,"DENORMALIZE");
end
