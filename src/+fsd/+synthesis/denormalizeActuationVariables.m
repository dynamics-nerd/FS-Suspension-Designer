function x_m = denormalizeActuationVariables(space,u)
%DENORMALIZEACTUATIONVARIABLES Exact endpoints, frozen axes and seed round trip.
fsd.synthesis.validateActuationDesignSpace(space); x_m=coordinateCore(space,u,"DENORMALIZE");
end
