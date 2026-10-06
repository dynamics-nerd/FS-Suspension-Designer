function handles = plotRollCenterMigration(sweepAnalysis, figureHandle)
%PLOTROLLCENTERMIGRATION Plot v0.4 roll-center migration in millimetres.

validateSweep(sweepAnalysis);
if nargin < 2 || isempty(figureHandle)
    figureHandle = figure("Name", "Roll-center migration");
elseif ~isgraphics(figureHandle, "figure")
    error("fsd:analysis:InvalidFigure", ...
        "figureHandle must be a valid MATLAB figure.");
end
layout = tiledlayout(figureHandle, 3, 1, ...
    "TileSpacing", "compact", "Padding", "compact");
travel_mm = sweepAnalysis.requestedWheelTravel_m * 1000;
fields = ["rollCenterZ_m", "rollCenterHeight_m", "rollCenterY_m"];
labels = ["RC Z [mm]", "RC height [mm]", "RC Y [mm]"];
titles = ["RC Z vs symmetric wheel travel", ...
    "RC height vs symmetric wheel travel", ...
    "RC lateral position vs symmetric wheel travel"];
handles = struct("figure", figureHandle, "layout", layout, ...
    "axes", gobjects(3, 1), "lines", gobjects(3, 1));
for index = 1:3
    handles.axes(index) = nexttile(layout);
    handles.lines(index) = plot(handles.axes(index), travel_mm, ...
        sweepAnalysis.(fields(index)) * 1000, ...
        "o-", "LineWidth", 1.5);
    grid(handles.axes(index), "on");
    xlabel(handles.axes(index), "Symmetric wheel travel [mm]");
    ylabel(handles.axes(index), labels(index));
    title(handles.axes(index), titles(index));
end
title(layout, sweepAnalysis.axleId + " axle roll-center migration");
end

function validateSweep(value)
required = ["kind", "axleId", "requestedWheelTravel_m", ...
    "rollCenterY_m", "rollCenterZ_m", "rollCenterHeight_m"];
if ~isstruct(value) || ~isscalar(value) || ...
        ~all(isfield(value, required)) || ...
        string(value.kind) ~= "AxleHeaveRollCenterAnalysis"
    error("fsd:analysis:InvalidAxleSweepAnalysis", ...
        "sweepAnalysis violates the axle migration contract.");
end
end
