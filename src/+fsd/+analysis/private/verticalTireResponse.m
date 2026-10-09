function tire = verticalTireResponse(model, height, ground)
%VERTICALTIRERESPONSE Stable replaceable vertical law boundary, no camber model.
raw = ground-height+model.unloadedRadius_m;
budget = 16*eps(max([abs(ground),abs(height),model.unloadedRadius_m,1]));
if raw == 0
    status = "CONTACT_TRANSITION";
elseif abs(raw) <= budget
    status = "CONTACT_NUMERICALLY_UNRESOLVED";
elseif raw > 0
    status = "IN_CONTACT";
else
    status = "AIRBORNE";
end
delta = max(0,raw); k = model.stiffness_N_per_m;
tire = struct("unloadedRadius_m",model.unloadedRadius_m, ...
    "loadedRadius_m",model.unloadedRadius_m-delta,"tireCompression_m",delta, ...
    "tireGap_m",max(0,-raw),"normalForce_N",k*delta, ...
    "tireStoredEnergy_J",0.5*k*delta^2,"contactStatus",status, ...
    "contactRoundoffBudget_m",budget,"rawTireCompression_m",raw);
end
