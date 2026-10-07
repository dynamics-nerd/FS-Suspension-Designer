function handles = plotSteeringSystem(steering, result, analysis, axesHandle)
%PLOTSTEERINGSYSTEM Plot rack, tie rods, contacts and wheel headings in 3D.

fsd.model.validateSteeringSystemGeometry(steering);
fsd.kinematics.validateSteeringResult(result, steering);
if ~isstruct(analysis) || string(analysis.kind) ~= "SteeringAxleAnalysis" || ...
        ~isequal(analysis.steeringSystemIdentity, steering.identity)
    error("fsd:analysis:InvalidSteeringAnalysis", ...
        "analysis must match the supplied steering system.");
end
if nargin < 4 || isempty(axesHandle)
    figureHandle = figure("Name", "Steering system geometry");
    axesHandle = axes(figureHandle);
elseif ~isgraphics(axesHandle, "axes")
    error("fsd:analysis:InvalidAxes", ...
        "axesHandle must be a valid MATLAB axes object.");
else
    figureHandle = ancestor(axesHandle, "figure");
end
if ~result.converged
    error("fsd:analysis:KinematicsNotConverged", ...
        "A converged steering result is required for plotting.");
end
wasHeld = ishold(axesHandle);
hold(axesHandle, "on");
cleanup = onCleanup(@() restoreHold(axesHandle, wasHeld));
rack = steering.rackGeometry;
staticRack = [rack.leftInnerStatic_m; rack.rightInnerStatic_m];
currentRack = [result.leftResult.tieRodInboardCurrent_m; ...
    result.rightResult.tieRodInboardCurrent_m];
tieLeft = [result.leftResult.tieRodInboardCurrent_m; ...
    result.leftResult.state.tieRodOutboard_m];
tieRight = [result.rightResult.tieRodInboardCurrent_m; ...
    result.rightResult.state.tieRodOutboard_m];
contacts = [analysis.left.geometricContact.point_m; ...
    analysis.right.geometricContact.point_m];
wheelCenters = [result.leftResult.state.wheelCenter_m; ...
    result.rightResult.state.wheelCenter_m];
axisIntersections = [analysis.left.steeringAxisRoadIntersection.point_m; ...
    analysis.right.steeringAxisRoadIntersection.point_m];
headingScale_m = 0.2 * rack.jointSeparation_m;
headings = [analysis.left.roadWheelHeading; analysis.right.roadWheelHeading];
handles = struct();
handles.figure = figureHandle;
handles.axes = axesHandle;
handles.staticRack = plot3(axesHandle, staticRack(:,1), staticRack(:,2), ...
    staticRack(:,3), "k--", "LineWidth", 1.2);
handles.currentRack = plot3(axesHandle, currentRack(:,1), currentRack(:,2), ...
    currentRack(:,3), "k-", "LineWidth", 2);
handles.tieRods = [plot3(axesHandle, tieLeft(:,1), tieLeft(:,2), ...
    tieLeft(:,3), "b-", "LineWidth", 1.5); ...
    plot3(axesHandle, tieRight(:,1), tieRight(:,2), ...
    tieRight(:,3), "r-", "LineWidth", 1.5)];
handles.contacts = plot3(axesHandle, contacts(:,1), contacts(:,2), ...
    contacts(:,3), "kv", "MarkerFaceColor", [0.1, 0.7, 0.2], ...
    "LineStyle", "none");
handles.axisIntersections = plot3(axesHandle, axisIntersections(:,1), ...
    axisIntersections(:,2), axisIntersections(:,3), "ko", ...
    "MarkerFaceColor", [1, 0.7, 0], "LineStyle", "none");
handles.headings = quiver3(axesHandle, wheelCenters(:,1), ...
    wheelCenters(:,2), wheelCenters(:,3), headings(:,1), headings(:,2), ...
    headings(:,3), headingScale_m, "m", "LineWidth", 1.5);
axis(axesHandle, "equal");
grid(axesHandle, "on");
xlabel(axesHandle, "X rearward [m]");
ylabel(axesHandle, "Y rightward [m]");
zlabel(axesHandle, "Z upward [m]");
title(axesHandle, "Rack travel " + ...
    compose("%.3f mm", 1000 * result.requestedRackTravel_m));
view(axesHandle, 3);
end

function restoreHold(axesHandle, wasHeld)
if isgraphics(axesHandle, "axes") && ~wasHeld
    hold(axesHandle, "off");
end
end
