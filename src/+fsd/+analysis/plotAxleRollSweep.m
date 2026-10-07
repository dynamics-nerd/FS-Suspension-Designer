function handles = plotAxleRollSweep(analysis, figureHandle)
%PLOTAXLEROLLSWEEP Plot camber, roll center and track versus body roll.

fsd.analysis.validateAxleRollSweepAnalysis(analysis);
if nargin < 2 || isempty(figureHandle)
    figureHandle = figure("Name", "Body-roll sweep analysis");
elseif ~isgraphics(figureHandle, "figure")
    error("fsd:analysis:InvalidFigure", ...
        "figureHandle must be a valid MATLAB figure.");
end
roll_deg = rad2deg(analysis.bodyRollAngle_rad);
layout = tiledlayout(figureHandle, 2, 2, ...
    "TileSpacing", "compact", "Padding", "compact");

handles = struct("figure", figureHandle, "layout", layout);
handles.camberAxes = nexttile(layout);
plot(handles.camberAxes, roll_deg, rad2deg(analysis.chassisCamber_rad), ...
    "--", "LineWidth", 1.2);
hold(handles.camberAxes, "on");
plot(handles.camberAxes, roll_deg, rad2deg(analysis.roadCamber_rad), ...
    "LineWidth", 1.5);
legend(handles.camberAxes, "chassis L", "chassis R", ...
    "road L", "road R", "Location", "best");
ylabel(handles.camberAxes, "Camber [deg]");

handles.rollCenterAxes = nexttile(layout);
plot(handles.rollCenterAxes, roll_deg, 1000*[analysis.rollCenterY_m, ...
    analysis.rollCenterZ_m, analysis.rollCenterRoadHeight_m], ...
    "LineWidth", 1.4);
legend(handles.rollCenterAxes, "RC Y", "RC Z", ...
    "RC road height", "Location", "best");
ylabel(handles.rollCenterAxes, "Distance [mm]");

handles.trackAxes = nexttile(layout);
plot(handles.trackAxes, roll_deg, 1000*[analysis.wheelCenterTrack_m, ...
    analysis.geometricContactTrack_m], "LineWidth", 1.4);
legend(handles.trackAxes, "wheel-center", "geometric-contact", ...
    "Location", "best");
ylabel(handles.trackAxes, "Track [mm]");

handles.trackChangeAxes = nexttile(layout);
plot(handles.trackChangeAxes, roll_deg, ...
    1000*[analysis.wheelCenterTrackChange_m, ...
    analysis.geometricContactTrackChange_m], "LineWidth", 1.4);
legend(handles.trackChangeAxes, "wheel-center", "geometric-contact", ...
    "Location", "best");
ylabel(handles.trackChangeAxes, "Track change [mm]");

allAxes = [handles.camberAxes, handles.rollCenterAxes, ...
    handles.trackAxes, handles.trackChangeAxes];
for axesHandle = allAxes
    grid(axesHandle, "on");
    xlabel(axesHandle, "Body roll angle [deg]");
end
title(layout, analysis.axleId + " axle body-roll sweep", ...
    "Interpreter", "none");
end
