function handles = plotDoubleWishboneGeometry(geometry, axesHandle)
%PLOTDOUBLEWISHBONEGEOMETRY Plot one static corner without App Designer.
%   HANDLES = ... (GEOMETRY) creates a figure and axes.
%   HANDLES = ... (GEOMETRY, AXESHANDLE) plots into supplied axes.

fsd.model.validateDoubleWishboneGeometry(geometry);
if nargin < 2 || isempty(axesHandle)
    figureHandle = figure("Name", "Static Double Wishbone Geometry");
    axesHandle = axes(figureHandle);
else
    if ~isgraphics(axesHandle, "axes")
        error("fsd:geometry:InvalidAxes", ...
            "axesHandle must be a valid MATLAB axes object.");
    end
    figureHandle = ancestor(axesHandle, "figure");
end

wasHeld = ishold(axesHandle);
hold(axesHandle, "on");
cleanup = onCleanup(@() restoreHold(axesHandle, wasHeld));

prefix = geometry.cornerId + "_";
ucaFwd = segment(geometry, prefix + "UCA_FWD_CHASSIS", prefix + "UBJ");
ucaAft = segment(geometry, prefix + "UCA_AFT_CHASSIS", prefix + "UBJ");
lcaFwd = segment(geometry, prefix + "LCA_FWD_CHASSIS", prefix + "LBJ");
lcaAft = segment(geometry, prefix + "LCA_AFT_CHASSIS", prefix + "LBJ");
tieRod = segment(geometry, prefix + "TIE_ROD_INBOARD", ...
    prefix + "TIE_ROD_OUTBOARD");
upright = segment(geometry, prefix + "UBJ", prefix + "LBJ");
wheelReference = segment(geometry, prefix + "WHEEL_CENTER", ...
    prefix + "CONTACT_PATCH");

handles = struct();
handles.figure = figureHandle;
handles.axes = axesHandle;
handles.uca = [ ...
    plot3(axesHandle, ucaFwd(:,1), ucaFwd(:,2), ucaFwd(:,3), ...
    "b-o", "LineWidth", 1.5); ...
    plot3(axesHandle, ucaAft(:,1), ucaAft(:,2), ucaAft(:,3), ...
    "b-o", "LineWidth", 1.5)];
handles.lca = [ ...
    plot3(axesHandle, lcaFwd(:,1), lcaFwd(:,2), lcaFwd(:,3), ...
    "r-o", "LineWidth", 1.5); ...
    plot3(axesHandle, lcaAft(:,1), lcaAft(:,2), lcaAft(:,3), ...
    "r-o", "LineWidth", 1.5)];
handles.tieRod = plot3(axesHandle, tieRod(:,1), tieRod(:,2), ...
    tieRod(:,3), "Color", [0.85 0.45 0.05], ...
    "LineStyle", "-", "Marker", "o", "LineWidth", 1.5);
handles.upright = plot3(axesHandle, upright(:,1), upright(:,2), ...
    upright(:,3), "k-o", "LineWidth", 2);
handles.wheelReference = plot3(axesHandle, wheelReference(:,1), ...
    wheelReference(:,2), wheelReference(:,3), "m--o", "LineWidth", 1.5);

xyz_m = geometry.hardpoints.xyz_m;
handles.hardpoints = scatter3(axesHandle, xyz_m(:,1), xyz_m(:,2), ...
    xyz_m(:,3), 36, "filled", "MarkerFaceColor", [0.2 0.2 0.2]);
handles.labels = gobjects(numel(geometry.hardpoints.ids), 1);
for index = 1:numel(geometry.hardpoints.ids)
    handles.labels(index) = text(axesHandle, ...
        xyz_m(index,1), xyz_m(index,2), xyz_m(index,3), ...
        " " + geometry.hardpoints.ids(index), "Interpreter", "none", ...
        "FontSize", 8);
end

wheelCenter = fsd.model.getPoint(geometry, prefix + "WHEEL_CENTER");
axisVector = geometry.wheel.wheelAxis;
plotSpan_m = max(max(xyz_m, [], 1) - min(xyz_m, [], 1));
arrowLength_m = 0.25 * plotSpan_m;
handles.wheelAxis = quiver3(axesHandle, wheelCenter(1), wheelCenter(2), ...
    wheelCenter(3), axisVector(1) * arrowLength_m, ...
    axisVector(2) * arrowLength_m, axisVector(3) * arrowLength_m, 0, ...
    "Color", [0 0.5 0], "LineWidth", 1.5, "MaxHeadSize", 0.5);

axis(axesHandle, "equal");
grid(axesHandle, "on");
xlabel(axesHandle, "X rearward [m]");
ylabel(axesHandle, "Y rightward [m]");
zlabel(axesHandle, "Z upward [m]");
title(axesHandle, geometry.cornerId + " static double wishbone");
view(axesHandle, 3);
end

function points = segment(geometry, pointIdA, pointIdB)
points = [ ...
    fsd.model.getPoint(geometry, pointIdA); ...
    fsd.model.getPoint(geometry, pointIdB)];
end

function restoreHold(axesHandle, wasHeld)
if isgraphics(axesHandle, "axes") && ~wasHeld
    hold(axesHandle, "off");
end
end
