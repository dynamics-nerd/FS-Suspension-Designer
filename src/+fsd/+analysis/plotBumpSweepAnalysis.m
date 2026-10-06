function handles = plotBumpSweepAnalysis(sweepAnalysis, figureHandle)
%PLOTBUMPSWEEPANALYSIS Plot five v0.3 curves in mm and degrees.

validateSweepAnalysis(sweepAnalysis);
if nargin < 2 || isempty(figureHandle)
    figureHandle = figure("Name", "Single-corner kinematic analysis");
elseif ~isgraphics(figureHandle, "figure")
    error("fsd:analysis:InvalidFigure", ...
        "figureHandle must be a valid MATLAB figure.");
end

layout = tiledlayout(figureHandle, 3, 2, ...
    "TileSpacing", "compact", "Padding", "compact");
travel_mm = sweepAnalysis.wheelTravel_m * 1000;
degreesPerRadian = 180 / pi;

handles = struct();
handles.figure = figureHandle;
handles.layout = layout;
handles.axes = gobjects(5, 1);
handles.lines = gobjects(5, 1);
labels = ["Camber", "Toe", "Bump steer", "Caster", ...
    "Kingpin inclination"];
values_rad = [ ...
    sweepAnalysis.camber_rad, ...
    sweepAnalysis.toe_rad, ...
    sweepAnalysis.bumpSteer_rad, ...
    sweepAnalysis.caster_rad, ...
    sweepAnalysis.kingpinInclination_rad];

for index = 1:5
    handles.axes(index) = nexttile(layout);
    handles.lines(index) = plot(handles.axes(index), travel_mm, ...
        values_rad(:, index) * degreesPerRadian, ...
        "o-", "LineWidth", 1.5);
    grid(handles.axes(index), "on");
    xlabel(handles.axes(index), "Wheel travel [mm]");
    ylabel(handles.axes(index), labels(index) + " [deg]");
    title(handles.axes(index), labels(index) + " vs wheel travel");
end
title(layout, sweepAnalysis.cornerId + ...
    " single-corner kinematic analysis");
end

function validateSweepAnalysis(value)
if ~isstruct(value) || ~isscalar(value)
    error("fsd:analysis:InvalidSweepAnalysis", ...
        "sweepAnalysis must be a scalar BumpSweepAnalysis struct.");
end
required = ["kind", "cornerId", "wheelTravel_m", "camber_rad", ...
    "toe_rad", "bumpSteer_rad", "caster_rad", ...
    "kingpinInclination_rad"];
for index = 1:numel(required)
    if ~isfield(value, required(index))
        error("fsd:analysis:InvalidSweepAnalysis", ...
            "BumpSweepAnalysis is missing field '%s'.", required(index));
    end
end
if ~isTextScalar(value.kind) || string(value.kind) ~= "BumpSweepAnalysis" || ...
        ~isnumeric(value.wheelTravel_m) || ...
        ~isreal(value.wheelTravel_m) || ...
        ~iscolumn(value.wheelTravel_m) || any(isinf(value.wheelTravel_m))
    error("fsd:analysis:InvalidSweepAnalysis", ...
        "sweepAnalysis does not satisfy the BumpSweepAnalysis contract.");
end
count = numel(value.wheelTravel_m);
fields = ["camber_rad", "toe_rad", "bumpSteer_rad", ...
    "caster_rad", "kingpinInclination_rad"];
for index = 1:numel(fields)
    fieldValue = value.(fields(index));
    if ~isnumeric(fieldValue) || ~isreal(fieldValue) || ...
            ~isequal(size(fieldValue), [count, 1]) || any(isinf(fieldValue))
        error("fsd:analysis:InvalidSweepAnalysis", ...
            "Analysis curve '%s' must be a real N-by-1 vector.", ...
            fields(index));
    end
end
end

function tf = isTextScalar(value)
tf = (ischar(value) && isrow(value)) || ...
    (isstring(value) && isscalar(value) && ~ismissing(value));
end
