function handles = plotSpringDamperSweep(analysis, model, actuation, figureHandle)
%PLOTSPRINGDAMPERSWEEP Nine mechanical views, with NaN gaps and limit markers.
% Display boundaries only: mm, N/mm; core data remains SI.
if nargin < 3, actuation = []; end
fsd.analysis.validateSpringDamperSweepAnalysis(analysis,model,actuation);
if nargin < 4 || isempty(figureHandle)
    figureHandle = figure("Name","Spring, damper and wheel rate");
elseif ~isgraphics(figureHandle,"figure")
    error("fsd:analysis:InvalidFigure","Expected a figure.");
end
layout = tiledlayout(figureHandle,3,3,"TileSpacing","compact","Padding","compact");
handles = struct("figure",figureHandle,"layout",layout,"axes",gobjects(9,1));
z = displayUnits(analysis.achievedWheelTravel_m,"length","mm");
curves = {displayUnits(analysis.springCompression_m,"length","mm"), ...
    analysis.springAxialForce_N,analysis.springWheelResistance_N, ...
    displayUnits(analysis.wheelRateTotal_N_per_m,"wheelRate","N/mm"), ...
    [displayUnits(analysis.wheelRateElastic_N_per_m,"wheelRate","N/mm"), ...
    displayUnits(analysis.wheelRateGeometric_N_per_m,"wheelRate","N/mm")], ...
    displayUnits(analysis.damperLength_m,"length","mm"),analysis.springStoredEnergy_J};
labels = ["Spring compression [mm]","Spring axial force [N]", ...
    "Spring wheel resistance [N]","Total tangent wheel rate [N/mm]", ...
    "Elastic / geometric rate [N/mm]","Damper length [mm]","Spring energy [J]"];
for i = 1:7
    handles.axes(i) = nexttile(layout);
    plot(handles.axes(i),z,curves{i},".-");
    xlabel(handles.axes(i),"Achieved wheel travel [mm]");
    ylabel(handles.axes(i),labels(i)); grid(handles.axes(i),"on");
end
legend(handles.axes(5),["Elastic","Geometric"],"Location","best");
yline(handles.axes(4),0,":");
if ~isempty(model.spring.solidHeight_m)
    yline(handles.axes(1),displayUnits(model.spring.freeLength_m-model.spring.solidHeight_m, ...
        "length","mm"),"--","Solid-height limit");
end
if ~isempty(model.damper.minimumLength_m)
    yline(handles.axes(6),displayUnits(model.damper.minimumLength_m,"length","mm"),"--","Minimum");
end
if ~isempty(model.damper.maximumLength_m)
    yline(handles.axes(6),displayUnits(model.damper.maximumLength_m,"length","mm"),"--","Maximum");
end
hold(handles.axes(6),"on");
outside = ~analysis.feasibleRelativeToProvidedLimits;
plot(handles.axes(6),z(outside),curves{6}(outside),"rx","DisplayName","Infeasible");
hold(handles.axes(1),"on");
unseated = analysis.springStatus == "SPRING_UNSEATED";
transition = analysis.springStatus == "SPRING_ENGAGEMENT_TRANSITION";
plot(handles.axes(1),z(unseated),curves{1}(unseated),"mv","DisplayName","Unseated");
plot(handles.axes(1),z(transition),curves{1}(transition),"ko","DisplayName","Engagement");
handles.axes(8) = nexttile(layout);
plot(handles.axes(8),analysis.damperVelocity_m_per_s,analysis.damperAxialResistance_N,".-");
xlabel(handles.axes(8),"Damper compression velocity [m/s]");
ylabel(handles.axes(8),"Damper resistance [N]"); grid(handles.axes(8),"on");
handles.axes(9) = nexttile(layout);
plot(handles.axes(9),analysis.wheelVelocity_m_per_s,analysis.damperWheelResistance_N,".-");
xlabel(handles.axes(9),"Wheel velocity [m/s]");
ylabel(handles.axes(9),"Damper wheel resistance [N]"); grid(handles.axes(9),"on");
title(layout,"Prescribed path response — not corner loads or equilibrium");
end

function y = displayUnits(x,quantity,toUnit)
y = nan(size(x)); mask = isfinite(x);
if quantity == "length", fromUnit = "m"; else, fromUnit = "N/m"; end
y(mask) = fsd.model.convertMechanicalUnits(x(mask),quantity,fromUnit,toUnit);
end
