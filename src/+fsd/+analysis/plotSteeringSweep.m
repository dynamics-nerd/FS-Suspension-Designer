function handles = plotSteeringSweep(analysis, figureHandle)
%PLOTSTEERINGSWEEP Plot v0.5 steering curves in presentation units.

if ~isstruct(analysis) || ~isscalar(analysis) || ...
        string(analysis.kind) ~= "RackSweepAnalysis"
    error("fsd:analysis:InvalidSteeringSweepAnalysis", ...
        "analysis must satisfy the RackSweepAnalysis contract.");
end
if nargin < 2 || isempty(figureHandle)
    figureHandle = figure("Name", "Rack steering analysis");
elseif ~isgraphics(figureHandle, "figure")
    error("fsd:analysis:InvalidFigure", ...
        "figureHandle must be a valid MATLAB figure.");
end
rack_mm = analysis.requestedRackTravel_m * 1000;
layout = tiledlayout(figureHandle, 5, 1, ...
    "TileSpacing", "compact", "Padding", "compact");
handles = struct("figure", figureHandle, "layout", layout, ...
    "axes", gobjects(5,1), "lines", gobjects(5,2));
handles.axes(1) = nexttile(layout);
handles.lines(1,:) = plotPair(handles.axes(1), rack_mm, ...
    analysis.roadWheelAngleLeft_rad * 180/pi, ...
    analysis.roadWheelAngleRight_rad * 180/pi);
ylabel(handles.axes(1), "Road angle [deg]");
handles.axes(2) = nexttile(layout);
handles.lines(2,:) = plotPair(handles.axes(2), rack_mm, ...
    analysis.rackInducedSteerLeft_rad * 180/pi, ...
    analysis.rackInducedSteerRight_rad * 180/pi);
ylabel(handles.axes(2), "Rack steer [deg]");
handles.axes(3) = nexttile(layout);
handles.lines(3,1) = plot(handles.axes(3), rack_mm, ...
    analysis.ackermannAngleError_rad * 180/pi, "k-o", "LineWidth", 1.2);
handles.lines(3,2) = handles.lines(3,1);
ylabel(handles.axes(3), "Ack. error [deg]");
handles.axes(4) = nexttile(layout);
handles.lines(4,:) = plotPair(handles.axes(4), rack_mm, ...
    analysis.scrubRadiusLeft_m * 1000, ...
    analysis.scrubRadiusRight_m * 1000);
ylabel(handles.axes(4), "Scrub [mm]");
handles.axes(5) = nexttile(layout);
handles.lines(5,:) = plotPair(handles.axes(5), rack_mm, ...
    analysis.mechanicalTrailLeft_m * 1000, ...
    analysis.mechanicalTrailRight_m * 1000);
ylabel(handles.axes(5), "Trail [mm]");
xlabel(handles.axes(5), "Rack travel [mm]");
for index = 1:5
    grid(handles.axes(index), "on");
end
legend(handles.axes(1), "FL", "FR", "Location", "best");
title(layout, "Steering, Ackermann, scrub and mechanical trail");
end

function lines = plotPair(ax, x, left, right)
hold(ax, "on");
cleanup = onCleanup(@() hold(ax, "off"));
lines = [plot(ax, x, left, "b-o", "LineWidth", 1.2), ...
    plot(ax, x, right, "r-s", "LineWidth", 1.2)];
end
