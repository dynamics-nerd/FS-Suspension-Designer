function handles = plotAxleRollFrontView(analysis, axesHandle)
%PLOTAXLEROLLFRONTVIEW Plot a rolled axle and its inclined road in YZ.

fsd.analysis.validateAxleRollAnalysis(analysis);
if ~analysis.converged
    error("fsd:analysis:KinematicsNotConverged", ...
        "A converged AxleRollAnalysis is required for plotting.");
end
if nargin < 2 || isempty(axesHandle)
    figureHandle = figure("Name", "Body-roll axle front view");
    axesHandle = axes(figureHandle);
elseif ~isgraphics(axesHandle, "axes")
    error("fsd:analysis:InvalidAxes", ...
        "axesHandle must be a valid MATLAB axes object.");
end

handles = fsd.analysis.plotAxleFrontView( ...
    analysis.axleStateAnalysis, axesHandle);
wasHeld = ishold(axesHandle);
hold(axesHandle, "on");
cleanup = onCleanup(@() restoreHold(axesHandle, wasHeld));
limits = xlim(axesHandle);
coefficients = analysis.roadLine.coefficients;
y = limits;
z = -(coefficients(1) .* y + coefficients(3)) ./ coefficients(2);
handles.road = plot(axesHandle, y, z, "Color", [0.1 0.55 0.15], ...
    "LineWidth", 2.2, "DisplayName", "road");

sides = [analysis.left, analysis.right];
handles.wheels = gobjects(2,1);
for index = 1:2
    center = sides(index).geometricContact.wheelCenter_m(2:3);
    contact = sides(index).geometricContact.point_m(2:3);
    radial = contact - center;
    endpoints = [center + radial; center - radial];
    handles.wheels(index) = plot(axesHandle, endpoints(:,1), ...
        endpoints(:,2), "k-", "LineWidth", 3);
end

midpoint = analysis.roadLine.point_yz_m;
span = max(diff(limits), 0.1);
normal = analysis.roadLine.coefficients(1:2);
handles.roadNormal = quiver(axesHandle, midpoint(1), midpoint(2), ...
    0.12*span*normal(1), 0.12*span*normal(2), 0, ...
    "Color", [0.1 0.55 0.15], "LineWidth", 1.5, ...
    "MaxHeadSize", 0.8);
title(axesHandle, compose("%s axle, body roll %+0.2f deg", ...
    analysis.axleId, rad2deg(analysis.bodyRollAngle_rad)), ...
    "Interpreter", "none");
end

function restoreHold(axesHandle, wasHeld)
if isgraphics(axesHandle, "axes") && ~wasHeld
    hold(axesHandle, "off");
end
end
