function handles = plotBumpResult(geometry, result, axesHandle)
%PLOTBUMPRESULT Compare static and one converged displaced configuration.

fsd.model.validateDoubleWishboneGeometry(geometry);
if ~isstruct(result) || ~isscalar(result) || ...
        ~isfield(result, "converged") || ~result.converged
    error("fsd:kinematics:InvalidResult", ...
        "A converged scalar KinematicResult is required.");
end
if nargin < 3 || isempty(axesHandle)
    figureHandle = figure("Name", "Static and displaced suspension");
    axesHandle = axes(figureHandle);
elseif ~isgraphics(axesHandle, "axes")
    error("fsd:geometry:InvalidAxes", ...
        "axesHandle must be a valid MATLAB axes object.");
end

handles = struct();
handles.static = fsd.geometry.plotDoubleWishboneGeometry(geometry, axesHandle);
holdState = ishold(axesHandle);
hold(axesHandle, "on");
cleanup = onCleanup(@() restoreHold(axesHandle, holdState));

prefix = geometry.cornerId + "_";
ucaFwd = [fsd.model.getPoint(geometry, prefix + "UCA_FWD_CHASSIS"); ...
    statePoint(result, prefix + "UBJ")];
ucaAft = [fsd.model.getPoint(geometry, prefix + "UCA_AFT_CHASSIS"); ...
    statePoint(result, prefix + "UBJ")];
lcaFwd = [fsd.model.getPoint(geometry, prefix + "LCA_FWD_CHASSIS"); ...
    statePoint(result, prefix + "LBJ")];
lcaAft = [fsd.model.getPoint(geometry, prefix + "LCA_AFT_CHASSIS"); ...
    statePoint(result, prefix + "LBJ")];
tieRod = [fsd.model.getPoint(geometry, prefix + "TIE_ROD_INBOARD"); ...
    statePoint(result, prefix + "TIE_ROD_OUTBOARD")];
upright = [statePoint(result, prefix + "UBJ"); ...
    statePoint(result, prefix + "LBJ")];
wheelReference = [statePoint(result, prefix + "WHEEL_CENTER"); ...
    statePoint(result, prefix + "CONTACT_PATCH")];

handles.currentMembers = gobjects(7, 1);
segments = {ucaFwd, ucaAft, lcaFwd, lcaAft, tieRod, upright, wheelReference};
colors = [0 0.65 1; 0 0.65 1; 1 0 0.8; 1 0 0.8; ...
    1 0.55 0; 0 0 0; 0.1 0.65 0.1];
for index = 1:numel(segments)
    points = segments{index};
    handles.currentMembers(index) = plot3(axesHandle, points(:,1), ...
        points(:,2), points(:,3), "-o", "Color", colors(index,:), ...
        "LineWidth", 2);
end

wheelCenter_m = statePoint(result, prefix + "WHEEL_CENTER");
staticXyz_m = geometry.hardpoints.xyz_m;
plotSpan_m = max(max(staticXyz_m, [], 1) - min(staticXyz_m, [], 1));
arrow_m = 0.25 * plotSpan_m * result.wheelAxis;
handles.currentWheelAxis = quiver3(axesHandle, ...
    wheelCenter_m(1), wheelCenter_m(2), wheelCenter_m(3), ...
    arrow_m(1), arrow_m(2), arrow_m(3), 0, ...
    "Color", [0.1 0.65 0.1], "LineWidth", 2);
title(axesHandle, sprintf("%s: travel %.3f mm, camber %.3f deg", ...
    geometry.cornerId, result.achievedWheelTravel_m * 1000, ...
    result.camber_rad * 180 / pi));
axis(axesHandle, "equal");
end

function point_m = statePoint(result, pointId)
match = result.state.pointIds == pointId;
if nnz(match) ~= 1
    error("fsd:kinematics:InvalidResult", ...
        "Result does not contain point %s.", pointId);
end
point_m = result.state.xyz_m(match, :);
end

function restoreHold(axesHandle, holdState)
if isgraphics(axesHandle, "axes") && ~holdState
    hold(axesHandle, "off");
end
end

