function [actuation,mechanical,changes,diagnostics] = buildActuationCandidate(space,x_m)
%BUILDACTUATIONCANDIDATE Native actuation and optional coilover reconstruction.
fsd.synthesis.validateActuationDesignSpace(space);
[actuation,mechanical,changes,diagnostics]=actuationBuildCore(space,x_m);
end
