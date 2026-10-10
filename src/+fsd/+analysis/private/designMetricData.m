function data = designMetricData(target, sources, references)
%DESIGNMETRICDATA Explicit adapters over fully validated native outputs.
% Missing/invalid outputs remain gaps. There is no interpolation or solver here.
t = target.definitionSI;
data = struct("x",zeros(0,1),"y",zeros(0,1),"valid",false(0,1), ...
    "reasons",strings(0,1),"connected",false(0,1),"sourceIdentity",[], ...
    "missingReason","MISSING_SOURCE:"+t.sourceId);
i = find(cellfun(@(s) s.id == t.sourceId,sources));
if isempty(i), return; end
s = sources{i}; r = s.result;
data.sourceIdentity = references{i};
if s.type ~= t.sourceType, data.missingReason = "SOURCE_TYPE_MISMATCH"; return; end
if ~isempty(t.requiredSourceIdentity) && ~isequaln(t.requiredSourceIdentity,references{i})
    data.missingReason = "SOURCE_IDENTITY_MISMATCH"; return;
end
reason = "UNAVAILABLE_NATIVE_RESULT"; scope = ""; connected = [];
switch s.type
    case "BUMP"
        scope = string(s.model.cornerId); x = r.requestedWheelTravel_m; valid = r.converged;
        reasons = r.status;
        switch t.metricId
            case "CAMBER", y = r.camber_rad;
            case "TOE", y = r.toe_rad;
            case "BUMP_STEER", y = r.bumpSteer_rad;
            case "CASTER", y = r.caster_rad;
            case "KPI", y = r.kingpinInclination_rad;
        end
    case "RACK"
        if ~isequal(s.sweep.requestedWheelTravel_m,t.conditions.wheelTravel_m)
            data.missingReason = "FIXED_WHEEL_TRAVEL_MISMATCH"; return;
        end
        x = r.requestedRackTravel_m; valid = r.converged; reasons = r.status;
        if t.scope.kind == "AXLE"
            scope = "FRONT"; y = r.ackermannAngleError_rad;
            valid = valid & r.ackermannStatus == "VALID"; reasons(~valid) = r.ackermannStatus(~valid);
            for k = 1:numel(valid)
                if valid(k) && (r.states(k).ackermann.leftIcr.isIllConditioned || r.states(k).ackermann.rightIcr.isIllConditioned)
                    valid(k) = false; reasons(k) = "ILL_CONDITIONED_ICR";
                end
            end
        else
            scope = t.scope.id;
            if ~any(scope == ["FL","FR"]), data.missingReason = "CORNER_SCOPE_MISMATCH"; return; end
            side = "left"; if scope == "FR", side = "right"; end
            y = nan(numel(x),1);
            for k = 1:numel(x)
                a = r.states(k).(side);
                switch t.metricId
                    case "TOE", y(k) = a.toe_rad;
                    case "ROAD_WHEEL_ANGLE", y(k) = a.roadWheelAngle_rad;
                    case "SCRUB_RADIUS", y(k) = a.scrubRadius_m;
                    case "MECHANICAL_TRAIL", y(k) = a.mechanicalTrail_m;
                end
                if any(t.metricId == ["SCRUB_RADIUS","MECHANICAL_TRAIL"]) && ...
                        a.steeringAxisRoadIntersection.isIllConditioned
                    valid(k) = false; reasons(k) = "ILL_CONDITIONED_STEERING_AXIS_INTERSECTION";
                end
            end
        end
    case "ROLL"
        if s.sweep.requestedAxleHeave_m ~= t.conditions.axleHeave_m
            data.missingReason = "FIXED_AXLE_HEAVE_MISMATCH"; return;
        end
        x = r.bodyRollAngle_rad; valid = r.converged; reasons = r.kinematicStatus;
        if t.scope.kind == "CORNER"
            ids = [string(s.model.leftGeometry.cornerId),string(s.model.rightGeometry.cornerId)];
            side = find(ids == t.scope.id);
            if isempty(side), data.missingReason = "CORNER_SCOPE_MISMATCH"; return; end
            scope = t.scope.id;
            switch t.metricId
                case "CAMBER", y = r.chassisCamber_rad(:,side);
                case "ROAD_CAMBER", y = r.roadCamber_rad(:,side);
                case "TOE", y = r.toe_rad(:,side);
            end
        else
            scope = string(s.model.axleId);
            switch t.metricId
                case "ROLL_CENTER_HEIGHT", y = r.rollCenterHeight_m;
                case "ROLL_CENTER_ROAD_HEIGHT", y = r.rollCenterRoadHeight_m;
                case "ROLL_CENTER_Y", y = r.rollCenterY_m;
                case "WHEEL_CENTER_TRACK_CHANGE", y = r.wheelCenterTrackChange_m;
            end
            if startsWith(t.metricId,"ROLL_CENTER")
                for k = 1:numel(valid)
                    if valid(k) && r.states(k).axleStateAnalysis.rollCenterIllConditioned
                        valid(k) = false; reasons(k) = "ILL_CONDITIONED_ROLL_CENTER";
                    elseif r.rollCenterStatus(k) ~= "FINITE"
                        valid(k) = false; reasons(k) = r.rollCenterStatus(k);
                    end
                end
            end
        end
    case {"ACTUATION","MECHANICAL"}
        scope = string(s.model.cornerId); x = r.requestedWheelTravel_m;
        if s.type == "ACTUATION"
            valid = r.converged & ~reshape([s.sweep.results.isIllConditioned],[],1); reasons = r.actuationStatus;
            branch = reshape(arrayfun(@(a) a.diagnostics.selectedCandidateIndex,s.sweep.results),[],1);
            connected = diff(branch) == 0;
            switch t.metricId
                case "DAMPER_COMPRESSION", y = r.damperCompression_m;
                case "MOTION_RATIO", y = r.damperMotionRatio;
                case "INSTALLATION_RATIO", y = r.installationRatio;
            end
            if t.metricId ~= "DAMPER_COMPRESSION" && ~startsWith(r.motionRatioStatus,"AVAILABLE")
                valid(:) = false; reasons(:) = r.motionRatioStatus;
            end
        else
            valid = r.path.converged & ~r.path.isIllConditioned & r.feasibleRelativeToProvidedLimits;
            switch t.metricId
                case "DAMPER_COMPRESSION", y = r.damperCompression_m;
                case "MOTION_RATIO", y = r.damperMotionRatio;
                case "INSTALLATION_RATIO", y = abs(r.damperMotionRatio);
                case "SPRING_AXIAL_FORCE", y = r.springAxialForce_N;
                case "SPRING_WHEEL_RESISTANCE", y = r.springWheelResistance_N;
                case "TANGENT_WHEEL_RATE", y = r.wheelRateTotal_N_per_m;
            end
            if any(t.metricId == ["MOTION_RATIO","INSTALLATION_RATIO","SPRING_WHEEL_RESISTANCE"])
                valid = valid & r.motionRatioStatus == "AVAILABLE";
            elseif t.metricId == "TANGENT_WHEEL_RATE"
                valid = valid & r.wheelRateStatus == "AVAILABLE";
            end
            reasons = designMechanicalReasons(r,t.metricId);
            if r.source.kind == "ActuationSweep"
                branch = reshape(arrayfun(@(a) a.diagnostics.selectedCandidateIndex,r.source.sweep.results),[],1);
                connected = diff(branch) == 0;
            end
        end
    case "GLOBAL_STATIC"
        if ~isfinite(r.selectedIndex)
            data.missingReason = "NO_SELECTED_GLOBAL_EQUILIBRIUM:"+r.solverOptions.selection; return;
        end
        a = r.alternatives{r.selectedIndex}; state = a.state;
        scope = t.scope.id; x = 0; valid = true; reasons = "AVAILABLE";
        switch t.metricId
            case "CORNER_LOAD"
                j = find(s.model.cornerIds == scope);
                y = state.normalForces_N(j);
            case "CROSSWEIGHT", y = state.crossweightActualSumFraction;
            case "REFERENCE_HEIGHT"
                j = find(s.model.options.rideHeightPointIds == t.subjectId);
                if isempty(j), data.missingReason = "MISSING_REFERENCE_POINT:"+t.subjectId; return; end
                y = state.rideHeights_m(j);
        end
    case "STATIC_LOADS"
        scope = t.scope.id; x = 0; valid = r.knownBalanceSatisfied; reasons = r.status;
        if t.metricId == "CORNER_LOAD", y = r.cornerLoads_N(s.model.cornerIds == scope);
        else, y = r.crossweightFraction; end
end
if scope ~= t.scope.id, data.missingReason = "SCOPE_MISMATCH"; return; end
x = x(:); y = y(:); valid = valid(:) & isfinite(y); reasons = string(reasons(:));
if isscalar(reasons), reasons = repmat(reasons,size(x)); end
reasons(valid) = "AVAILABLE"; reasons(~valid & reasons == "AVAILABLE") = reason;
if isempty(connected), connected = true(max(numel(x)-1,0),1); end
if numel(x) > 1
    if all(diff(x) < 0)
        x = flipud(x); y = flipud(y); valid = flipud(valid); reasons = flipud(reasons); connected = flipud(connected);
    elseif ~all(diff(x) > 0)
        data.missingReason = "NON_MONOTONIC_SOURCE_COORDINATE"; return;
    end
end
data.x = x; data.y = y; data.valid = valid; data.reasons = reasons;
data.connected = connected; data.missingReason = "";
end
