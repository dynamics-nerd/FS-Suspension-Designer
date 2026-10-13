function x_m = denormalizeAxleVariables(space,u)
%DENORMALIZEAXLEVARIABLES Reuse v0.12 endpoint, seed and frozen-axis policy.
fsd.synthesis.validateAxleDesignSpace(space);
x_m=coordinateCore(space,u,"DENORMALIZE");
end
