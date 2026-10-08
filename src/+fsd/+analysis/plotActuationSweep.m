function handles = plotActuationSweep(analysis, figureHandle)
%PLOTACTUATIONSWEEP Plot v0.7 actuation curves in presentation units.

if ~isstruct(analysis) || ~isscalar(analysis) || ...
        ~isfield(analysis, "kind") || ...
        string(analysis.kind) ~= "ActuationSweepAnalysis"
    error("fsd:analysis:InvalidActuationSweepAnalysis", ...
        "analysis must be an ActuationSweepAnalysis.");
end
if nargin < 2 || isempty(figureHandle)
    figureHandle = figure("Name", "Actuation kinematics");
elseif ~isgraphics(figureHandle, "figure")
    error("fsd:analysis:InvalidFigure", ...
        "figureHandle must be a valid MATLAB figure.");
end
wheelTravel_mm = analysis.requestedWheelTravel_m * 1000;
layout = tiledlayout(figureHandle, 2, 2, ...
    "TileSpacing", "compact", "Padding", "compact");
handles = struct("figure", figureHandle, "layout", layout, ...
    "axes", gobjects(4,1), "lines", gobjects(4,1));
handles.axes(1) = nexttile(layout);
handles.lines(1) = plot(handles.axes(1), wheelTravel_mm, ...
    analysis.rockerAngle_rad*180/pi, "b-o", "LineWidth", 1.2);
ylabel(handles.axes(1), "Rocker angle [deg]");
handles.axes(2) = nexttile(layout);
handles.lines(2) = plot(handles.axes(2), wheelTravel_mm, ...
    analysis.damperCompression_m*1000, "r-o", "LineWidth", 1.2);
ylabel(handles.axes(2), "Damper compression [mm]");
handles.axes(3) = nexttile(layout);
handles.lines(3) = plot(handles.axes(3), wheelTravel_mm, ...
    analysis.damperMotionRatio, "k-o", "LineWidth", 1.2);
ylabel(handles.axes(3), "Damper motion ratio [-]");
handles.axes(4) = nexttile(layout);
handles.lines(4) = plot(handles.axes(4), wheelTravel_mm, ...
    analysis.installationRatio, "m-o", "LineWidth", 1.2);
ylabel(handles.axes(4), "Installation ratio [-]");
for index = 1:4
    xlabel(handles.axes(index), "Wheel travel [mm]");
    grid(handles.axes(index), "on");
end
title(layout, "Actuation geometry and motion-ratio migration");
end
