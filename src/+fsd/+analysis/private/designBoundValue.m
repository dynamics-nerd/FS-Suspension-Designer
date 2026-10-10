function [value, reason] = designBoundValue(binding, scope, candidate)
%DESIGNBOUNDVALUE Explicit bindings into existing model values, not computed targets.
value = []; reason = "MISSING_BOUND_MODEL"; d = candidate.definitionSI;
if startsWith(binding,"HARDPOINT_") || binding == "HARDPOINT_POSITION"
    for i = 1:numel(d.geometries)
        g = d.geometries{i};
        if g.cornerId ~= scope.cornerId, continue; end
        xyz = g.hardpoints.xyz_m(g.hardpoints.ids == scope.id,:); % already validated model/scope
        switch binding
            case "HARDPOINT_X", value = xyz(1);
            case "HARDPOINT_Y", value = xyz(2);
            case "HARDPOINT_Z", value = xyz(3);
            otherwise, value = xyz;
        end
        reason = "AVAILABLE"; return;
    end
elseif any(binding == ["SPRING_RATE","SPRING_PRELOAD"])
    for i = 1:numel(d.sources)
        s = d.sources{i};
        if s.id ~= scope.id || s.type ~= "MECHANICAL" || s.model.cornerId ~= scope.cornerId, continue; end
        if binding == "SPRING_RATE", value = s.model.spring.rate_N_per_m;
        else, value = s.model.spring.preloadCompression_m; end
        reason = "AVAILABLE"; return;
    end
elseif startsWith(binding,"VEHICLE_") && ~isempty(d.vehicle)
    v = d.vehicle;
    switch binding
        case "VEHICLE_WHEELBASE", value = v.definitionSI.wheelbase;
        case "VEHICLE_FRONT_TRACK", value = v.definitionSI.frontTrack;
        case "VEHICLE_REAR_TRACK", value = v.definitionSI.rearTrack;
        case "VEHICLE_MASS", value = v.totalMass_kg;
    end
    if all(isfinite(value)), reason = "AVAILABLE"; else, value = []; end
end
end
