function handles = plotStaticVehicleLoads(vehicle, loads, figureHandle)
%PLOTSTATICVEHICLELOADS Contact plan and loads; indeterminate loads are not bars.
fsd.analysis.validateStaticVehicleLoads(loads,vehicle);
if nargin < 3 || isempty(figureHandle), figureHandle = figure("Name","Static vehicle loads"); end
if ~isgraphics(figureHandle,"figure"), error("fsd:analysis:InvalidFigure","Expected figure."); end
layout = tiledlayout(figureHandle,1,2);
ax1 = nexttile(layout); p = vehicle.contactPoints_m;
plot(ax1,p([1,2,4,3,1],1),p([1,2,4,3,1],2),"o-"); hold(ax1,"on");
text(ax1,p(:,1),p(:,2),vehicle.cornerIds);
if all(isfinite(vehicle.cg_m(1:2))), plot(ax1,vehicle.cg_m(1),vehicle.cg_m(2),"rx","MarkerSize",10); end
xlabel(ax1,"X rearward [m]"); ylabel(ax1,"Y rightward [m]");
axis(ax1,"equal"); grid(ax1,"on");
title(ax1,sprintf("L=%.3g m; tracks F/R=%.3g/%.3g m", ...
    vehicle.definitionSI.wheelbase,vehicle.definitionSI.frontTrack,vehicle.definitionSI.rearTrack));
ax2 = nexttile(layout);
if all(isfinite(loads.cornerLoads_N))
    bar(ax2,categorical(vehicle.cornerIds,vehicle.cornerIds),loads.cornerLoads_N);
    title(ax2,sprintf("%s; sum %.3g N; F/R %.3g/%.3g N; CW %.3g%%", ...
        loads.cornerLoadSourceKind,sum(loads.cornerLoads_N), ...
        loads.frontAxleLoad_N,loads.rearAxleLoad_N,100*loads.crossweightFraction));
else
    text(ax2,0.05,0.5,loads.status,"Interpreter","none");
    xlim(ax2,[0,1]); ylim(ax2,[0,1]); title(ax2,"No unique corner-load distribution");
end
ylabel(ax2,"Vertical normal [N]"); grid(ax2,"on");
handles = struct("figure",figureHandle,"layout",layout,"axes",[ax1;ax2]);
end
