function value = damperLaw(damper, velocity)
%DAMPERLAW Signed resisting force; branch determined by axial compression speed.
value = struct("damperVelocity_m_per_s",velocity,"damperAxialResistance_N",NaN, ...
    "damperDissipatedPower_W",NaN,"damperLocalCoefficient_Ns_per_m",NaN, ...
    "damperStatus","UNAVAILABLE_VELOCITY");
if ~isfinite(velocity), return; end
if velocity == 0
    value.damperAxialResistance_N = 0;
    value.damperDissipatedPower_W = 0;
    value.damperStatus = "ZERO_VELOCITY";
    if damper.modelType == "LINEAR_ASYMMETRIC" && ...
            damper.compressionCoefficient_Ns_per_m == damper.reboundCoefficient_Ns_per_m
        value.damperLocalCoefficient_Ns_per_m = damper.compressionCoefficient_Ns_per_m;
    end
    return;
end
if velocity > 0
    branch = "COMPRESSION";
    coefficient = damper.compressionCoefficient_Ns_per_m;
    table = damper.compressionTable;
else
    branch = "REBOUND";
    coefficient = damper.reboundCoefficient_Ns_per_m;
    table = damper.reboundTable;
end
if damper.modelType == "LINEAR_ASYMMETRIC"
    force = coefficient*velocity;
    value.damperLocalCoefficient_Ns_per_m = coefficient;
else
    speed = abs(velocity);
    if speed > table(end,1)
        value.damperStatus = "DAMPER_VELOCITY_OUT_OF_RANGE";
        return;
    end
    force = sign(velocity)*interp1(table(:,1),table(:,2),speed,"linear");
    % At an internal knot the local tangent is not unique.
    if ~any(speed == table(2:end-1,1))
        i = find(table(:,1) >= speed,1);
        value.damperLocalCoefficient_Ns_per_m = ...
            (table(i,2)-table(i-1,2))/(table(i,1)-table(i-1,1));
    end
end
value.damperAxialResistance_N = force;
value.damperDissipatedPower_W = force*velocity;
value.damperStatus = branch;
end
