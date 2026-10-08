function [first, second, statuses, quality] = springDamperPathDerivatives(model, source, path)
%SPRINGDAMPERPATHDERIVATIVES Local quadratic plus separate sensitivity gates.
% c'' is computed directly from c; normalized rcond alone is not sufficient.
z = path.achievedWheelTravel_m; c = path.damperCompression_m;
valid = path.converged & isfinite(z) & isfinite(c);
n = numel(z); first = nan(n,1); second = first;
statuses = repmat("AVAILABLE",n,1);
policy = springDamperDerivativePolicy(model);
[errorC,errorZ,errorKind] = springDamperSampleResolution(model,source,path,policy);
empty = nan(n,1);
quality = struct("policy",policy,"sampleResolutionKind",errorKind, ...
    "sampleCompressionError_m",errorC,"sampleWheelTravelError_m",errorZ, ...
    "stencilIndices",nan(n,3),"firstWeights_per_m",nan(n,3), ...
    "secondWeights_per_m2",nan(n,3),"matrixReciprocalCondition",empty, ...
    "candidateMotionRatio",empty,"candidateCurvature_per_m",empty, ...
    "candidateWheelRate_N_per_m",empty,"motionRatioAbsoluteError",empty, ...
    "curvatureAbsoluteError_per_m",empty,"geometricRateAbsoluteError_N_per_m",empty, ...
    "wheelRateAbsoluteError_N_per_m",empty,"motionRatioErrorLimit",empty, ...
    "curvatureErrorLimit_per_m",empty,"wheelRateErrorLimit_N_per_m",empty, ...
    "motionRatioStatus",statuses,"intrinsicCurvatureResolved",false(n,1), ...
    "wheelRateImpactResolved",false(n,1));
if n < 3
    if all(valid), statuses(:) = "UNAVAILABLE_INSUFFICIENT_SAMPLES";
    else, statuses(:) = "UNAVAILABLE_PATH_GAP"; end
    quality.motionRatioStatus = statuses; return;
elseif all(valid) && ~(all(diff(z) > 0) || all(diff(z) < 0))
    statuses(:) = "UNAVAILABLE_NONMONOTONIC_WHEEL_TRAVEL";
    quality.motionRatioStatus = statuses; return;
end
for i = 1:n
    j = max(1,min(i-1,n-2)) + (0:2);
    quality.stencilIndices(i,:) = j;
    if ~all(valid(j))
        statuses(i) = "UNAVAILABLE_PATH_GAP";
        quality.motionRatioStatus(i) = statuses(i); continue;
    end
    steps = diff(z(j));
    if ~(all(steps > 0) || all(steps < 0))
        statuses(i) = "UNAVAILABLE_NONMONOTONIC_WHEEL_TRAVEL";
        quality.motionRatioStatus(i) = statuses(i); continue;
    end
    dz = z(j)-z(i); h = max(abs(dz)); t = dz/h;
    matrix = [ones(3,1),t,t.^2]; reciprocalCondition = rcond(matrix);
    quality.matrixReciprocalCondition(i) = reciprocalCondition;
    if any(path.isIllConditioned(j)) || ...
            min(abs(diff(z(j)))) <= 64*eps(max([abs(z(j));1])) || ...
            reciprocalCondition <= sqrt(eps)
        statuses(i) = "UNAVAILABLE_ILL_CONDITIONED";
        quality.motionRatioStatus(i) = statuses(i); continue;
    end
    coefficients = matrix \ (c(j)-c(i));
    mr = coefficients(2)/h; curvature = 2*coefficients(3)/h^2;
    w1 = zeros(3,1); w2 = w1;
    for k = 1:3
        others = [1:k-1,k+1:3];
        denominator = (t(k)-t(others(1)))*(t(k)-t(others(2)));
        w1(k) = -(t(others(1))+t(others(2)))/(denominator*h);
        w2(k) = 2/(denominator*h^2);
    end
    slope = max([abs(mr);abs(diff(c(j))./diff(z(j)))]);
    effectiveError = errorC(j)+slope*errorZ(j);
    errorMR = sum(abs(w1).*effectiveError)+policy.roundoffUlps*eps(abs(mr));
    errorCurvature = sum(abs(w2).*effectiveError)+policy.roundoffUlps*eps(abs(curvature));
    if source.kind == "ActuationSweep"
        publishedMR = source.analysis.damperMotionRatio(i);
        if ~isfinite(publishedMR)
            quality.motionRatioStatus(i) = "UNAVAILABLE_SOURCE_MOTION_RATIO";
        else
            errorMR = errorMR+abs(publishedMR-mr);
            mr = publishedMR;
        end
    end
    spring = springLaw(model.spring,c(i)); force = spring.springAxialForce_N;
    rate = model.spring.rate_N_per_m;
    elastic = rate*mr^2;
    if spring.springStatus == "SPRING_UNSEATED", elastic = 0; end
    candidateRate = elastic+force*curvature;
    errorForce = rate*errorC(i)+policy.roundoffUlps*eps(abs(force));
    errorGeometric = abs(force)*errorCurvature+abs(curvature)*errorForce + ...
        errorForce*errorCurvature+policy.roundoffUlps*eps(abs(force*curvature));
    errorElastic = rate*(2*abs(mr)*errorMR+errorMR^2);
    if spring.springStatus == "SPRING_UNSEATED", errorElastic = 0; end
    errorRate = errorElastic+errorGeometric+policy.roundoffUlps*eps(abs(candidateRate));
    mrLimit = policy.absoluteScaleFraction+policy.relativeBudget*abs(mr);
    curvatureLimit = policy.absoluteScaleFraction/policy.referenceLength_m + ...
        policy.relativeBudget*abs(curvature);
    rateLimit = policy.absoluteScaleFraction*rate+policy.relativeBudget*abs(candidateRate);
    quality.firstWeights_per_m(i,:) = w1'; quality.secondWeights_per_m2(i,:) = w2';
    quality.candidateMotionRatio(i) = mr; quality.candidateCurvature_per_m(i) = curvature;
    quality.candidateWheelRate_N_per_m(i) = candidateRate;
    quality.motionRatioAbsoluteError(i) = errorMR;
    quality.curvatureAbsoluteError_per_m(i) = errorCurvature;
    quality.geometricRateAbsoluteError_N_per_m(i) = errorGeometric;
    quality.wheelRateAbsoluteError_N_per_m(i) = errorRate;
    quality.motionRatioErrorLimit(i) = mrLimit;
    quality.curvatureErrorLimit_per_m(i) = curvatureLimit;
    quality.wheelRateErrorLimit_N_per_m(i) = rateLimit;
    quality.intrinsicCurvatureResolved(i) = isfinite(errorCurvature) && errorCurvature <= curvatureLimit;
    quality.wheelRateImpactResolved(i) = isfinite(errorRate) && errorRate <= rateLimit;
    if any(~isfinite([mr,errorMR]))
        quality.motionRatioStatus(i) = "UNAVAILABLE_NONFINITE_DERIVATIVE";
    else
        if quality.motionRatioStatus(i) == "AVAILABLE" && errorMR > mrLimit
            quality.motionRatioStatus(i) = "UNAVAILABLE_NUMERICAL_RESOLUTION";
        end
        if quality.motionRatioStatus(i) == "AVAILABLE", first(i) = mr; end
    end
    if any(~isfinite([curvature,errorCurvature,errorRate]))
        statuses(i) = "UNAVAILABLE_NONFINITE_DERIVATIVE";
    else
        if ~quality.intrinsicCurvatureResolved(i) || ~quality.wheelRateImpactResolved(i)
            statuses(i) = "UNAVAILABLE_NUMERICAL_RESOLUTION";
        else
            second(i) = curvature;
        end
    end
end
end
