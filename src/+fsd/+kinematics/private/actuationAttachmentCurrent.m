function [pointCurrent_m, diagnostics] = actuationAttachmentCurrent( ...
    actuation, sourceResult)
%ACTUATIONATTACHMENTCURRENT Transform the body-fixed suspension pickup.

body = string(actuation.suspensionAttachment.body);
pointStatic_m = actuation.suspensionAttachment.pointStatic_m;
diagnostics = struct( ...
    "body", body, ...
    "bodyRotation_rad", NaN, ...
    "pivotAxisPoint_m", [NaN, NaN, NaN], ...
    "pivotAxisDirection_unit", [NaN, NaN, NaN], ...
    "localLeverArm_m", NaN);
if body == "UPRIGHT"
    pose = sourceResult.uprightPose;
    pointCurrent_m = fsd.geometry.transformPointsRigid( ...
        pointStatic_m, pose.referencePointStatic_m, pose.translation_m, ...
        pose.rotationMatrix);
    return
end

identity = actuation.cornerGeometryIdentity;
prefix = string(identity.cornerId) + "_";
if body == "UCA"
    forwardId = prefix + "UCA_FWD_CHASSIS";
    aftId = prefix + "UCA_AFT_CHASSIS";
    ballJointId = prefix + "UBJ";
    ballJointCurrent_m = sourceResult.state.ubj_m;
elseif body == "LCA"
    forwardId = prefix + "LCA_FWD_CHASSIS";
    aftId = prefix + "LCA_AFT_CHASSIS";
    ballJointId = prefix + "LBJ";
    ballJointCurrent_m = sourceResult.state.lbj_m;
else
    error("fsd:kinematics:InvalidAttachmentBody", ...
        "Unsupported suspension attachment body.");
end
axisPoint_m = identityPoint(identity, forwardId);
axisEnd_m = identityPoint(identity, aftId);
axisDirection = axisEnd_m - axisPoint_m;
axisDirection = axisDirection ./ norm(axisDirection, 2);
ballJointStatic_m = identityPoint(identity, ballJointId);
angle_rad = fsd.geometry.signedRotationAboutAxis(axisPoint_m, ...
    axisDirection, ballJointStatic_m, ballJointCurrent_m);
pointCurrent_m = fsd.geometry.rotatePointsAboutAxis( ...
    pointStatic_m, axisPoint_m, axisDirection, angle_rad);
diagnostics.bodyRotation_rad = angle_rad;
diagnostics.pivotAxisPoint_m = axisPoint_m;
diagnostics.pivotAxisDirection_unit = axisDirection;
diagnostics.localLeverArm_m = norm(cross( ...
    pointStatic_m-axisPoint_m, axisDirection), 2);
end

function point_m = identityPoint(identity, pointId)
match = identity.hardpointIds == pointId;
if nnz(match) ~= 1
    error("fsd:kinematics:InvalidAttachmentBody", ...
        "Required suspension point is missing from the identity.");
end
point_m = identity.hardpointXyz_m(match,:);
end
