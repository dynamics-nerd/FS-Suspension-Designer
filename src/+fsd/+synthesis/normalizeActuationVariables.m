function u = normalizeActuationVariables(space,x_m)
%NORMALIZEACTUATIONVARIABLES Reuse canonical v0.12 closed-box coordinates.
fsd.synthesis.validateActuationDesignSpace(space); u=coordinateCore(space,x_m,"NORMALIZE");
end
