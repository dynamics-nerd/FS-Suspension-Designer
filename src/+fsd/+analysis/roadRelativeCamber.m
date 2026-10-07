function camber_rad = roadRelativeCamber(wheelAxis, cornerId, bodyRollAngle_rad)
%ROADRELATIVECAMBER Camber after expressing the wheel axis in road frame.

frame = fsd.geometry.bodyRollRoadFrame(bodyRollAngle_rad);
if ~isnumeric(wheelAxis) || ~isreal(wheelAxis) || ...
        ~isequal(size(wheelAxis), [1, 3]) || any(~isfinite(wheelAxis))
    error("fsd:analysis:InvalidWheelAxis", ...
        "wheelAxis must be a finite real 1-by-3 vector.");
end
axisRoad = (frame.chassisToRoadRotation * double(wheelAxis).').';
camber_rad = fsd.analysis.camberFromWheelAxis(axisRoad, cornerId);
end
