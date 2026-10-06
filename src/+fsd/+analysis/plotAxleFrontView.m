function handles = plotAxleFrontView(analysis, axesHandle)
%PLOTAXLEFRONTVIEW Plot v0.4 axle construction in mathematical YZ view.

validateAnalysis(analysis);
if nargin < 2 || isempty(axesHandle)
    figureHandle = figure("Name", "Axle front-view roll center");
    axesHandle = axes(figureHandle);
elseif ~isgraphics(axesHandle, "axes")
    error("fsd:analysis:InvalidAxes", ...
        "axesHandle must be a valid MATLAB axes object.");
else
    figureHandle = ancestor(axesHandle, "figure");
end

wasHeld = ishold(axesHandle);
hold(axesHandle, "on");
cleanup = onCleanup(@() restoreHold(axesHandle, wasHeld));
contacts = [analysis.left.geometricContact.point_m(2:3); ...
    analysis.right.geometricContact.point_m(2:3)];
centers = [analysis.left.geometricContact.wheelCenter_m(2:3); ...
    analysis.right.geometricContact.wheelCenter_m(2:3)];
finitePoints = [contacts; centers];
if string(analysis.left.instantCenter.status) == "FINITE"
    finitePoints(end + 1, :) = analysis.left.instantCenter.point_yz_m;
end
if string(analysis.right.instantCenter.status) == "FINITE"
    finitePoints(end + 1, :) = analysis.right.instantCenter.point_yz_m;
end
ySpan = max(finitePoints(:, 1)) - min(finitePoints(:, 1));
if ySpan <= 0
    ySpan = 1;
end
yRange = [min(finitePoints(:, 1)) - 0.1 * ySpan, ...
    max(finitePoints(:, 1)) + 0.1 * ySpan];
zSpan = max(finitePoints(:, 2)) - min(finitePoints(:, 2));
if zSpan <= 0
    zSpan = 1;
end
zRange = [min(finitePoints(:, 2)) - 0.1 * zSpan, ...
    max(finitePoints(:, 2)) + 0.1 * zSpan];

handles = struct();
handles.figure = figureHandle;
handles.axes = axesHandle;
handles.upperLines = [ ...
    plotLine(axesHandle, analysis.left.instantCenter.upperLine, ...
        yRange, zRange, [0 0.35 0.9], "--"); ...
    plotLine(axesHandle, analysis.right.instantCenter.upperLine, ...
        yRange, zRange, [0 0.35 0.9], "--")];
handles.lowerLines = [ ...
    plotLine(axesHandle, analysis.left.instantCenter.lowerLine, ...
        yRange, zRange, [0.85 0.1 0.15], "--"); ...
    plotLine(axesHandle, analysis.right.instantCenter.lowerLine, ...
        yRange, zRange, [0.85 0.1 0.15], "--")];
handles.constructionLines = [ ...
    plotLine(axesHandle, ...
        analysis.left.rollCenterConstructionLine, yRange, zRange, ...
        [0.45 0.1 0.6], "-"); ...
    plotLine(axesHandle, ...
        analysis.right.rollCenterConstructionLine, yRange, zRange, ...
        [0.45 0.1 0.6], "-")];
handles.wheelCenters = plot(axesHandle, centers(:, 1), centers(:, 2), ...
    "ks", "MarkerFaceColor", [0.8 0.8 0.8], "LineStyle", "none");
handles.contacts = plot(axesHandle, contacts(:, 1), contacts(:, 2), ...
    "kv", "MarkerFaceColor", [0.1 0.65 0.1], "LineStyle", "none");
handles.instantCenters = gobjects(0);
for side = ["left", "right"]
    instantCenter = analysis.(side).instantCenter;
    if string(instantCenter.status) == "FINITE"
        handles.instantCenters(end + 1, 1) = plot(axesHandle, ...
            instantCenter.instantCenterY_m, ...
            instantCenter.instantCenterZ_m, "ko", ...
            "MarkerFaceColor", [1 0.65 0]);
    else
        detail = string(instantCenter.status);
        if detail == "INFINITE"
            detail = detail + " direction [" + ...
                compose("%.4g", instantCenter.direction_yz(1)) + ", " + ...
                compose("%.4g", instantCenter.direction_yz(2)) + "]";
        end
        text(axesHandle, analysis.(side).geometricContact.point_m(2), ...
            analysis.(side).geometricContact.point_m(3), ...
            "  IC " + side + ": " + detail, ...
            "Interpreter", "none");
    end
end
handles.rollCenter = gobjects(0);
if string(analysis.status) == "FINITE"
    handles.rollCenter = plot(axesHandle, analysis.rollCenterY_m, ...
        analysis.rollCenterZ_m, "p", "MarkerSize", 12, ...
        "MarkerFaceColor", [0.95 0.1 0.7], "MarkerEdgeColor", "k");
elseif string(analysis.status) == "INFINITE"
    text(axesHandle, mean(yRange), max(zRange), ...
        "RC at infinity; direction [" + ...
        compose("%.4g", analysis.rollCenterDirection_yz(1)) + ", " + ...
        compose("%.4g", analysis.rollCenterDirection_yz(2)) + "]", ...
        "HorizontalAlignment", "center", "Interpreter", "none");
end
handles.centerline = xline(axesHandle, 0, "k:", "Y=0");
handles.roadReference = gobjects(0);
if isfinite(analysis.roadReferenceZ_m)
    handles.roadReference = yline(axesHandle, ...
        analysis.roadReferenceZ_m, "Color", [0.2 0.55 0.2], ...
        "LineStyle", ":", "Label", "contact reference");
end
axis(axesHandle, "equal");
grid(axesHandle, "on");
xlabel(axesHandle, "Y rightward [m]");
ylabel(axesHandle, "Z upward [m]");
title(axesHandle, analysis.axleId + " axle front view: " + ...
    analysis.status, "Interpreter", "none");
end

function handle = plotLine(ax, line, yRange, zRange, color, style)
handle = gobjects(1);
if string(line.status) ~= "FINITE"
    return
end
coefficients = double(line.coefficients);
if abs(coefficients(2)) > eps
    y = yRange;
    z = -(coefficients(1) * y + coefficients(3)) / coefficients(2);
else
    y = repmat(-coefficients(3) / coefficients(1), 1, 2);
    z = zRange;
end
handle = plot(ax, y, z, "Color", color, ...
    "LineStyle", style, "LineWidth", 1.3);
end

function validateAnalysis(value)
required = ["kind", "axleId", "status", "rollCenterY_m", ...
    "rollCenterZ_m", "roadReferenceZ_m", "left", "right"];
if ~isstruct(value) || ~isscalar(value) || ...
        ~all(isfield(value, required)) || ...
        string(value.kind) ~= "AxleRollCenterAnalysis"
    error("fsd:analysis:InvalidAxleAnalysis", ...
        "analysis must satisfy the AxleRollCenterAnalysis contract.");
end
end

function restoreHold(axesHandle, wasHeld)
if isgraphics(axesHandle, "axes") && ~wasHeld
    hold(axesHandle, "off");
end
end
