function handles = plotCornerStaticEquilibrium(result, figureHandle)
%PLOTCORNERSTATICEQUILIBRIUM Valid force path and roots, never bridges invalid data.
fsd.analysis.validateCornerStaticEquilibrium(result);
if nargin < 2 || isempty(figureHandle), figureHandle = figure("Name","Local corner equilibrium"); end
if ~isgraphics(figureHandle,"figure"), error("fsd:analysis:InvalidFigure","Expected figure."); end
ax = axes(figureHandle); hold(ax,"on");
m = result.sourceMechanical; z = m.achievedWheelTravel_m*1000;
force = m.springWheelResistance_N; force(~result.validSampleMask) = NaN;
% Individual segments also preserve branch/status gaps.
for i = 1:numel(z)-1
    if result.validSegmentMask(i), plot(ax,z(i:i+1),force(i:i+1),"b.-"); end
end
plot(ax,z,force,"b.","LineStyle","none");
yline(ax,result.targetSupport_N,"--","Prescribed support");
for i = 1:result.rootCount
    r = result.roots(i);
    plot(ax,1000*r.equilibriumWheelTravel_m,r.wheelSupportForce_N,"ro");
    text(ax,1000*r.equilibriumWheelTravel_m,r.wheelSupportForce_N,r.localStabilityStatus, ...
        "Interpreter","none","VerticalAlignment","bottom");
end
xlabel(ax,"Wheel travel [mm], bump positive"); ylabel(ax,"Spring wheel resistance [N]");
title(ax,result.status,"Interpreter","none"); grid(ax,"on");
handles = struct("figure",figureHandle,"axes",ax);
end
