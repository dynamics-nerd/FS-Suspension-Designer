function u = normalizeVariables(space,x_m)
%NORMALIZEVARIABLES Map SI coordinates to [0,1]; zero-width axes map to zero.
fsd.synthesis.validateDesignSpace(space);
u = coordinateCore(space,x_m,"NORMALIZE");
end
