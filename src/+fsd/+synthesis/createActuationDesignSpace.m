function space = createActuationDesignSpace(seed,actuationSeed,mechanicalSeed,specification,plan)
%CREATEACTUATIONDESIGNSPACE Fixed suspension; bounded actuation geometry only.
space=actuationSpaceCore(seed,actuationSeed,mechanicalSeed,specification,plan);
end
