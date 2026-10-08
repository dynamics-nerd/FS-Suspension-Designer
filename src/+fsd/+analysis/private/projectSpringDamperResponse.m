function state = projectSpringDamperResponse(state, model)
%PROJECTSPRINGDAMPERRESPONSE Virtual-work gradient, not tire/contact load.
mr = state.damperMotionRatio;
if ~isfinite(mr)
    state.wheelRateStatus = "UNAVAILABLE_MOTION_RATIO";
    return;
end
if isfinite(state.springAxialForce_N)
    state.springWheelResistance_N = state.springAxialForce_N*mr;
end
if isfinite(state.damperAxialResistance_N)
    state.damperWheelResistance_N = state.damperAxialResistance_N*mr;
end
state.damperWheelLocalCoefficient_Ns_per_m = ...
    state.damperLocalCoefficient_Ns_per_m*mr^2;
if model.damper.modelType == "LINEAR_ASYMMETRIC"
    state.damperWheelCompressionCoefficient_Ns_per_m = ...
        model.damper.compressionCoefficient_Ns_per_m*mr^2;
    state.damperWheelReboundCoefficient_Ns_per_m = ...
        model.damper.reboundCoefficient_Ns_per_m*mr^2;
end
if ~isfinite(state.springAxialForce_N)
    return;
elseif state.springStatus == "SPRING_ENGAGEMENT_TRANSITION"
    state.wheelRateStatus = "SPRING_ENGAGEMENT_TRANSITION";
elseif state.springSolidStatus == "COIL_BIND_LIMIT"
    state.wheelRateStatus = "COIL_BIND_LIMIT";
else
    if state.springStatus == "SPRING_UNSEATED"
        state.wheelRateElastic_N_per_m = 0;
    else
        state.wheelRateElastic_N_per_m = model.spring.rate_N_per_m*mr^2;
    end
    if ~isfinite(state.motionRatioDerivative_per_m)
        state.wheelRateStatus = state.derivativeStatus;
        return;
    end
    if state.springStatus == "SPRING_UNSEATED"
        state.wheelRateGeometric_N_per_m = 0;
    else
        state.wheelRateGeometric_N_per_m = ...
            state.springAxialForce_N*state.motionRatioDerivative_per_m;
    end
    state.wheelRateTotal_N_per_m = ...
        state.wheelRateElastic_N_per_m+state.wheelRateGeometric_N_per_m;
    state.wheelRateStatus = "AVAILABLE";
    if state.wheelRateTotal_N_per_m < 0
        state.stiffnessDiagnostic = "NEGATIVE_TANGENT_STIFFNESS";
    else
        state.stiffnessDiagnostic = "NONNEGATIVE_TANGENT_STIFFNESS";
    end
end
end
