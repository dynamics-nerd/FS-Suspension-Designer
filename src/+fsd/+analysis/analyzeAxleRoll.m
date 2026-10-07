function analysis = analyzeAxleRoll(axle, result)
%ANALYZEAXLEROLL Analyze camber, FVIC, RC and track for body roll.

fsd.model.validateAxleGeometry(axle);
try
    fsd.kinematics.validateAxleRollResult(result);
catch cause
    exception = MException("fsd:analysis:InvalidAxleRollResult", ...
        "result violates the AxleRollResult contract.");
    exception = addCause(exception, cause);
    throwAsCaller(exception);
end
identity = fsd.model.axleIdentity(axle);
if ~isequal(identity, result.axleIdentity)
    error("fsd:analysis:AxleGeometryMismatch", ...
        "The roll result belongs to a different axle geometry.");
end
leftRadius_m = wheelContactRadius(axle.leftGeometry);
rightRadius_m = wheelContactRadius(axle.rightGeometry);
reference = staticReference(axle, leftRadius_m, rightRadius_m, identity);
analysis = analyzeAxleRollCore(axle, result, reference, ...
    leftRadius_m, rightRadius_m, identity);
fsd.analysis.validateAxleRollAnalysis(analysis);
end

function reference = staticReference(axle, leftRadius_m, rightRadius_m, identity)
base = analyzeAxleStateCore(axle, [], [], 0, leftRadius_m, ...
    rightRadius_m, identity);
leftCenter = fsd.model.getPoint(axle.leftGeometry, ...
    string(axle.leftGeometry.cornerId) + "_WHEEL_CENTER");
rightCenter = fsd.model.getPoint(axle.rightGeometry, ...
    string(axle.rightGeometry.cornerId) + "_WHEEL_CENTER");
contacts = [base.left.geometricContact.point_m; ...
    base.right.geometricContact.point_m];
reference = struct( ...
    "bodyRollAngle_rad", 0, "axleHeave_m", 0, ...
    "wheelCenterTrack_m", rightCenter(2) - leftCenter(2), ...
    "geometricContactTrack_m", contacts(2,2) - contacts(1,2));
end
