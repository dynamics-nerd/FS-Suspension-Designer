function [geometry, actuation, definition] = actuationFixture( ...
    orientationMode, attachmentBody, actuationType, variant)
%ACTUATIONFIXTURE Deterministic geometric fixture for v0.7 tests.

if nargin < 1, orientationMode = "YZ_PLANE"; end
if nargin < 2, attachmentBody = "UPRIGHT"; end
if nargin < 3, actuationType = "PUSHROD"; end
if nargin < 4, variant = "NORMAL"; end
axle = translationAxleFixture("FRONT");
geometry = axle.leftGeometry;
orientationMode = upper(string(orientationMode));
variant = upper(string(variant));

if orientationMode == "YZ_PLANE"
    axisDirection = [1, 0, 0];
    radial = [0, 0.1, 0];
    tangent = [0, 0, 0.1];
elseif orientationMode == "XZ_PLANE"
    axisDirection = [0, 1, 0];
    radial = [0.1, 0, 0];
    tangent = [0, 0, -0.1];
elseif orientationMode == "CUSTOM"
    axisDirection = [1, 2, 3];
    axisDirection = axisDirection ./ norm(axisDirection);
    radial = cross(axisDirection, [0, 0, 1]);
    radial = 0.1 .* radial ./ norm(radial);
    tangent = cross(axisDirection, radial);
else
    error("fsd:test:InvalidOrientation", "Invalid orientation mode.");
end
axisPoint = [0, 0, 0];
rodPoint = axisPoint + radial;
damperPoint = axisPoint + tangent;
if variant == "TANGENT"
    suspensionPoint = axisPoint + 4 .* radial;
elseif variant == "TANGENT_POSITIVE"
    suspensionPoint = axisPoint - 2 .* radial;
elseif variant == "UNDERCONSTRAINED"
    suspensionPoint = axisPoint + 0.05 .* axisDirection;
else
    suspensionPoint = axisPoint + 1.5 .* radial + tangent;
end
damperChassis = damperPoint + [0.12, -0.08, 0.06];
if norm(cross(damperChassis-damperPoint, axisDirection)) < 0.01
    damperChassis = damperPoint + [0.10, 0.12, -0.07];
end

axis = struct("point", axisPoint);
if orientationMode == "CUSTOM"
    axis.direction = axisDirection;
end
definition = struct( ...
    "actuationType", string(actuationType), ...
    "suspensionAttachment", struct( ...
        "body", string(attachmentBody), "point", suspensionPoint), ...
    "rocker", struct( ...
        "orientationMode", orientationMode, ...
        "axis", axis, ...
        "actuationRodPoint", rodPoint, ...
        "damperPoint", damperPoint), ...
    "damper", struct("chassisPoint", damperChassis), ...
    "metadata", struct("description", "v0.7 analytic test fixture"));
actuation = fsd.model.createActuationGeometry( ...
    geometry, definition, "m");
end
