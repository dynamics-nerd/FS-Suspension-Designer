function [axle,changes] = buildAxleCandidate(space,x_m)
%BUILDAXLECANDIDATE Deterministic authorized reconstruction of both corners.
fsd.synthesis.validateAxleDesignSpace(space);
[axle,changes]=axleBuildCore(space,x_m);
end
