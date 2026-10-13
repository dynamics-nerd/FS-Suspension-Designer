function [steering,changes,diagnostics] = buildSteeringCandidate(space,x_m)
%BUILDSTEERINGCANDIDATE Rebuild both corners, rack and derived static tie lengths.
fsd.synthesis.validateSteeringDesignSpace(space);
[steering,changes,diagnostics]=steeringBuildCore(space,x_m);
end
