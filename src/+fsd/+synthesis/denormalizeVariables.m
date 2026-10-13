function x_m = denormalizeVariables(space,u)
%DENORMALIZEVARIABLES Reversible affine map; endpoints and seed preserved.
fsd.synthesis.validateDesignSpace(space);
x_m = coordinateCore(space,u,"DENORMALIZE");
end
