function [geometry, changes] = buildCandidateGeometry(space,x_m)
%BUILDCANDIDATEGEOMETRY Apply only declared bounded SI coordinate changes.
fsd.synthesis.validateDesignSpace(space);
[geometry,changes] = buildCore(space,x_m);
end
