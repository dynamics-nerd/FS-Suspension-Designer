function u = normalizeAxleVariables(space,x_m)
%NORMALIZEAXLEVARIABLES Independent physical coordinates to the closed unit box.
fsd.synthesis.validateAxleDesignSpace(space);
u=coordinateCore(space,x_m,"NORMALIZE");
end
