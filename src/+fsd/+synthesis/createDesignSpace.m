function space = createDesignSpace(seed, specification, plan)
%CREATEDESIGNSPACE Bind v0.11 FREE/RANGE coordinates to one immutable corner.
% PLAN.travel_m is the ordered BUMP grid; PLAN.solverOptions is optional.
space = spaceCore(seed,specification,plan);
end
