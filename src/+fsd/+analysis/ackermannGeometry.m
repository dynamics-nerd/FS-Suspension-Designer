function analysis = ackermannGeometry(leftContact_m, leftHeading, ...
    rightContact_m, rightHeading, rearAxleX_m, ...
    leftRackInduced_rad, rightRackInduced_rad)
%ACKERMANNGEOMETRY Analyze bilateral wheel headings against a rear-axle line.

leftContact_m = validatePoint(leftContact_m, "leftContact_m");
rightContact_m = validatePoint(rightContact_m, "rightContact_m");
leftHeading = validateHeading(leftHeading, "leftHeading");
rightHeading = validateHeading(rightHeading, "rightHeading");
values = [rearAxleX_m, leftRackInduced_rad, rightRackInduced_rad];
if ~isnumeric(values) || ~isreal(values) || any(~isfinite(values))
    error("fsd:analysis:InvalidAckermannInput", ...
        "Rear-axle reference and steering deflections must be finite.");
end
leftIcr = impliedIcr(leftContact_m, leftHeading, rearAxleX_m);
rightIcr = impliedIcr(rightContact_m, rightHeading, rearAxleX_m);
leftAngle_rad = atan2(leftHeading(2), -leftHeading(1));
rightAngle_rad = atan2(rightHeading(2), -rightHeading(1));
turnSignal_rad = 0.5 * (leftRackInduced_rad + rightRackInduced_rad);
nearStraightTolerance_rad = sqrt(eps);

status = "VALID";
direction = "RIGHT";
innerCorner = "FR";
outerCorner = "FL";
actualInner_rad = rightAngle_rad;
actualOuter_rad = leftAngle_rad;
idealOuter_rad = NaN;
angleError_rad = NaN;
icrMismatch_m = NaN;
diagnostic = "";
if max(abs([leftRackInduced_rad, rightRackInduced_rad])) <= ...
        nearStraightTolerance_rad
    status = "NEAR_STRAIGHT";
    direction = "STRAIGHT";
    innerCorner = "";
    outerCorner = "";
    actualInner_rad = NaN;
    actualOuter_rad = NaN;
    diagnostic = "Rack-induced steering is too small to define a turn.";
elseif leftRackInduced_rad * rightRackInduced_rad < 0
    status = "AMBIGUOUS_TURN";
    direction = "AMBIGUOUS";
    innerCorner = "";
    outerCorner = "";
    actualInner_rad = NaN;
    actualOuter_rad = NaN;
    diagnostic = "The two rack-induced steering angles imply opposite turns.";
elseif turnSignal_rad < 0
    direction = "LEFT";
    innerCorner = "FL";
    outerCorner = "FR";
    actualInner_rad = leftAngle_rad;
    actualOuter_rad = rightAngle_rad;
end

if status == "VALID"
    if string(leftIcr.status) ~= "FINITE" || ...
            string(rightIcr.status) ~= "FINITE"
        status = "ICR_UNDEFINED";
        diagnostic = "At least one wheel implies an ICR at infinity.";
    else
        icrMismatch_m = leftIcr.y_m - rightIcr.y_m;
        if direction == "RIGHT"
            innerIcrY_m = rightIcr.y_m;
            outerContact_m = leftContact_m;
        else
            innerIcrY_m = leftIcr.y_m;
            outerContact_m = rightContact_m;
        end
        idealHeading = tangentHeading( ...
            outerContact_m, [rearAxleX_m, innerIcrY_m]);
        idealOuter_rad = atan2(idealHeading(2), -idealHeading(1));
        angleError_rad = fsd.geometry.wrapAngle( ...
            actualOuter_rad - idealOuter_rad);
    end
end
analysis = struct( ...
    "schemaVersion", "0.5.0", ...
    "kind", "AckermannGeometryAnalysis", ...
    "status", status, ...
    "steeringDirection", direction, ...
    "innerCorner", innerCorner, ...
    "outerCorner", outerCorner, ...
    "leftIcr", leftIcr, ...
    "rightIcr", rightIcr, ...
    "icrMismatch_m", icrMismatch_m, ...
    "actualInnerRoadWheelAngle_rad", actualInner_rad, ...
    "actualOuterRoadWheelAngle_rad", actualOuter_rad, ...
    "idealOuterRoadWheelAngle_rad", idealOuter_rad, ...
    "ackermannAngleError_rad", angleError_rad, ...
    "conditioning", min(leftIcr.conditioning, rightIcr.conditioning), ...
    "diagnostic", diagnostic);
end

function icr = impliedIcr(contact_m, heading, rearAxleX_m)
denominator = heading(2);
numerator = denominator * contact_m(2) - ...
    heading(1) * (rearAxleX_m - contact_m(1));
conditioning = abs(denominator);
if conditioning <= 100 * eps
    icr = icrStruct("INFINITE", NaN, [1, 0], ...
        conditioning, false, "Wheel heading is parallel to the rear axle line.");
    return
end
y_m = numerator / denominator;
ill = conditioning <= sqrt(eps);
diagnostic = "";
if ill
    diagnostic = "The finite wheel ICR is ill-conditioned.";
end
icr = icrStruct("FINITE", y_m, [y_m, 1], ...
    conditioning, ill, diagnostic);
end

function value = icrStruct(status, y_m, homogeneousPoint, ...
        conditioning, ill, diagnostic)
value = struct( ...
    "status", status, ...
    "y_m", y_m, ...
    "homogeneousPoint", homogeneousPoint, ...
    "conditioning", conditioning, ...
    "isIllConditioned", logical(ill), ...
    "diagnostic", diagnostic);
end

function heading = tangentHeading(contact_m, icr_xy_m)
radius = icr_xy_m - contact_m(1:2);
candidate = [-radius(2), radius(1)];
if candidate(1) > 0
    candidate = -candidate;
end
candidate = candidate ./ norm(candidate);
heading = [candidate, 0];
end

function point = validatePoint(value, name)
if ~isnumeric(value) || ~isreal(value) || ...
        ~isequal(size(value), [1, 3]) || any(~isfinite(value))
    error("fsd:analysis:InvalidAckermannInput", ...
        "%s must be a finite real 1-by-3 point.", name);
end
point = double(value);
end

function heading = validateHeading(value, name)
if ~isnumeric(value) || ~isreal(value) || ...
        ~isequal(size(value), [1, 3]) || any(~isfinite(value)) || ...
        abs(value(3)) > 100 * eps || abs(norm(value) - 1) > 1000 * eps || ...
        value(1) >= 0
    error("fsd:analysis:InvalidAckermannInput", ...
        "%s must be a unit horizontal forward heading.", name);
end
heading = double(value);
end
