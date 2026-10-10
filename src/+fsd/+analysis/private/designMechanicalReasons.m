function reasons = designMechanicalReasons(r,metric)
%DESIGNMECHANICALREASONS Diagnostic priority; does NOT change availability/physics.
% Highest first: upstream failure, conditioning, invalid seats, coil excess,
% damper travel excess, metric-specific quality, axial status, generic fallback.
reasons = r.springStatus;
if any(metric == ["MOTION_RATIO","INSTALLATION_RATIO","SPRING_WHEEL_RESISTANCE"])
    reasons = r.motionRatioStatus;
elseif metric == "TANGENT_WHEEL_RATE"
    reasons = r.wheelRateStatus;
    missingMR = reasons == "UNAVAILABLE_MOTION_RATIO";
    reasons(missingMR) = r.motionRatioStatus(missingMR);
end
bad = r.damperTravelStatus == "DAMPER_TRAVEL_LIMIT_EXCEEDED";
reasons(bad) = r.damperTravelStatus(bad);
bad = r.springSolidStatus == "COIL_BIND_EXCEEDED";
reasons(bad) = r.springSolidStatus(bad);
bad = r.springSolidStatus == "INVALID_SPRING_SEAT_GEOMETRY";
reasons(bad) = r.springSolidStatus(bad);
reasons(r.path.isIllConditioned) = "UNAVAILABLE_ILL_CONDITIONED";
failed = ~r.path.converged;
reasons(failed) = "UNAVAILABLE_ACTUATION_FAILURE";
if r.source.kind == "ActuationSweep"
    for i = find(failed(:))'
        reasons(i) = r.source.sweep.results(i).status;
    end
end
end
