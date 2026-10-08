function handles = plotActuationResult(actuation, result, axesHandle)
%PLOTACTUATIONRESULT Plot static/current rod, rocker, damper and 3-D axis.

fsd.model.validateActuationGeometry(actuation);
fsd.kinematics.validateActuationResult(result, actuation);
if ~result.converged
    error("fsd:kinematics:InvalidActuationResult", ...
        "A converged ActuationResult is required for plotting.");
end
if nargin < 3 || isempty(axesHandle)
    figureHandle = figure("Name", "Actuation geometry");
    axesHandle = axes(figureHandle);
elseif ~isgraphics(axesHandle, "axes")
    error("fsd:geometry:InvalidAxes", ...
        "axesHandle must be a valid MATLAB axes object.");
end

holdState = ishold(axesHandle);
hold(axesHandle, "on");
cleanup = onCleanup(@() restoreHold(axesHandle, holdState));
staticSuspension_m = actuation.suspensionAttachment.pointStatic_m;
staticRod_m = actuation.rocker.actuationRodPoint.pointStatic_m;
staticDamper_m = actuation.rocker.damperPoint.pointStatic_m;
damperChassis_m = actuation.damper.chassisPoint.point_m;
handles = struct();
handles.staticRod = segment(axesHandle, ...
    [staticSuspension_m; staticRod_m], [0.6,0.6,0.6], "--");
handles.staticRocker = segment(axesHandle, ...
    [staticRod_m; staticDamper_m], [0.6,0.6,0.6], "--");
handles.staticDamper = segment(axesHandle, ...
    [staticDamper_m; damperChassis_m], [0.6,0.6,0.6], "--");
handles.currentRod = segment(axesHandle, ...
    [result.suspensionAttachmentCurrent_m; ...
    result.rockerRodPointCurrent_m], [0.85,0.2,0.1], "-");
handles.currentRocker = segment(axesHandle, ...
    [result.rockerRodPointCurrent_m; ...
    result.rockerDamperPointCurrent_m], [0.1,0.35,0.9], "-");
handles.currentDamper = segment(axesHandle, ...
    [result.rockerDamperPointCurrent_m; damperChassis_m], ...
    [0.15,0.65,0.2], "-");

axisPoint_m = actuation.rocker.axis.point_m;
axisDirection = actuation.rocker.axis.direction_unit;
span_m = max([actuation.actuationRod.staticLength_m, ...
    actuation.damper.staticLength_m, 0.05]);
axisEnds_m = [axisPoint_m-span_m*axisDirection; ...
    axisPoint_m+span_m*axisDirection];
handles.rockerAxis = plot3(axesHandle, axisEnds_m(:,1), ...
    axisEnds_m(:,2), axisEnds_m(:,3), "k-.", "LineWidth", 1.5);
handles.axisPoint = scatter3(axesHandle, axisPoint_m(1), ...
    axisPoint_m(2), axisPoint_m(3), 45, "k", "filled");
axis(axesHandle, "equal");
grid(axesHandle, "on");
xlabel(axesHandle, "X [m]");
ylabel(axesHandle, "Y [m]");
zlabel(axesHandle, "Z [m]");
title(axesHandle, sprintf("%s %s: rocker %.3f deg", ...
    actuation.cornerId, actuation.actuationType, ...
    result.rockerAngle_rad*180/pi));
view(axesHandle, 3);
end

function handle = segment(ax, points, color, style)
handle = plot3(ax, points(:,1), points(:,2), points(:,3), ...
    style + "o", "Color", color, "LineWidth", 2);
end

function restoreHold(axesHandle, holdState)
if isgraphics(axesHandle, "axes") && ~holdState
    hold(axesHandle, "off");
end
end
