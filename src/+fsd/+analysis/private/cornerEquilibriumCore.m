function result = cornerEquilibriumCore(model, actuation, mechanical, demand, options)
%CORNEREQUILIBRIUMCORE All roots of the admissible sampled piecewise-linear path.
timer = tic; z = mechanical.achievedWheelTravel_m;
force = mechanical.springWheelResistance_N; residual = force-demand;
tol = options.forceAbsoluteTolerance_N+options.forceRelativeTolerance*max(demand,1);
valid = mechanical.path.converged & isfinite(z) & isfinite(force) & ...
    mechanical.feasibleRelativeToProvidedLimits & isfinite(mechanical.damperMotionRatio);
inRange = z >= options.travelInterval_m(1) & z <= options.travelInterval_m(2);
roots = repmat(rootTemplate(),0,1); flats = zeros(0,2); unresolved = zeros(0,2);
validSegments = false(max(numel(z)-1,0),1);
% Exact sample matches do not require an available second derivative.
for i = 1:numel(z)
    if valid(i) && inRange(i) && abs(residual(i)) <= tol
        roots(end+1,1) = makeRoot(i,i,0,z(i),"PATH_SAMPLE_EQUILIBRIUM"); %#ok<AGROW>
    end
end
for i = 1:numel(z)-1
    j = i+1;
    sameBranch = mechanical.springStatus(i) == mechanical.springStatus(j);
    if ~all(valid([i,j])) || z(i) == z(j) || ~sameBranch, continue; end
    % Preserve input adjacency, never sort or bridge disconnected/invalid branches.
    if i > 1 && valid(i-1) && sign(z(i)-z(i-1)) ~= sign(z(j)-z(i)), continue; end
    lower = max(min(z([i,j])),options.travelInterval_m(1));
    upper = min(max(z([i,j])),options.travelInterval_m(2));
    if lower > upper, continue; end
    validSegments(i) = true;
    if abs(residual(i)) <= tol && abs(residual(j)) <= tol
        rates = mechanical.wheelRateTotal_N_per_m([i,j]);
        if mechanical.springStatus(i) == "SPRING_UNSEATED" || ...
                (all(isfinite(rates)) && all(abs(rates) <= options.stiffnessZeroTolerance_N_per_m))
            if lower < upper
                flats(end+1,:) = [lower,upper]; %#ok<AGROW>
            else
                fraction = (lower-z(i))/(z(j)-z(i));
                roots(end+1,1) = makeRoot(i,j,fraction,lower,"PATH_INTERPOLATED_EQUILIBRIUM"); %#ok<AGROW>
            end
        else
            % Equal endpoint forces with nonzero/unknown tangents do not prove a plateau.
            unresolved(end+1,:) = [lower,upper]; %#ok<AGROW>
        end
    elseif residual(i)*residual(j) < 0
        fraction = -residual(i)/(force(j)-force(i));
        travel = z(i)+fraction*(z(j)-z(i));
        if travel >= lower && travel <= upper
            roots(end+1,1) = makeRoot(i,j,fraction,travel,"PATH_INTERPOLATED_EQUILIBRIUM"); %#ok<AGROW>
        end
    end
end
% Endpoint matches duplicate crossing roots only within the numerical travel resolution.
filterDiagnostics = struct("algorithm","SORTED_INTERVAL_SWEEP", ...
    "rootComparisonCount",0,"intervalAdvanceCount",0, ...
    "inputRootCount",0,"inputFlatIntervalCount",size(flats,1));
if ~isempty(roots)
    [~,order] = sort([roots.equilibriumWheelTravel_m]); roots = roots(order);
    keep = true(numel(roots),1);
    travelRoundoff = 64*eps(max([abs(z(isfinite(z)));1]));
    for i = 2:numel(roots)
        if abs(roots(i).equilibriumWheelTravel_m-roots(i-1).equilibriumWheelTravel_m) <= ...
                travelRoundoff
            keep(i) = false;
        end
    end
    roots = roots(keep);
    if ~isempty(flats)
        [keep,filterDiagnostics] = rootsOutsideFlatIntervals([roots.equilibriumWheelTravel_m],flats);
        roots = roots(keep);
    end
end
selected = NaN; status = "NO_EQUILIBRIUM_IN_VALID_TRAVEL";
if ~any(valid & inRange) && ~any(validSegments), status = "INSUFFICIENT_VALID_PATH"; end
if ~isempty(flats)
    status = "FLAT_EQUILIBRIUM_INTERVAL";
elseif isscalar(roots)
    selected = 1; status = "UNIQUE_LOCAL_EQUILIBRIUM";
elseif numel(roots) > 1
    status = "MULTIPLE_LOCAL_EQUILIBRIA";
    if options.rootSelection == "NEAREST_REFERENCE"
        distances = abs([roots.equilibriumWheelTravel_m]-options.referenceTravel_m);
        chosen = find(distances == min(distances));
        if isscalar(chosen), selected = chosen;
        else, status = "AMBIGUOUS_REFERENCE_SELECTION"; end
    end
end
selectedRoot = rootTemplate();
if isfinite(selected), selectedRoot = roots(selected); end
result = struct("schemaVersion","0.9.0","kind","CornerStaticEquilibrium", ...
    "cornerId",model.cornerId,"modelIdentity",model.identity, ...
    "sourceModel",model,"sourceActuation",actuation,"sourceMechanical",mechanical, ...
    "targetSupport_N",demand,"options",options,"status",status, ...
    "roots",roots,"rootCount",numel(roots),"flatIntervals_m",flats, ...
    "flatIntervalFilterDiagnostics",filterDiagnostics, ...
    "matchingEndpointUnresolvedIntervals_m",unresolved, ...
    "validSampleMask",valid,"validSegmentMask",validSegments, ...
    "selectedRootIndex",selected,"selectedRoot",selectedRoot, ...
    "equilibriumWheelTravel_m",selectedRoot.equilibriumWheelTravel_m, ...
    "selectionAvailable",isfinite(selected),"forceTolerance_N",tol, ...
    "method","SAMPLED_PIECEWISE_LINEAR","rootCompleteness","SAMPLED_PATH_ONLY", ...
    "globalChassisEquilibriumSolved",false,"elapsedTime_s",toc(timer));
    function r = makeRoot(i,j,a,travel,method)
        r = rootTemplate(); r.equilibriumWheelTravel_m = travel;
        r.method = method; r.bracketIndices = [i,j]; r.interpolationFraction = a;
        fields = ["springCompression_m","springAxialForce_N","damperLength_m","damperMotionRatio"];
        for field = fields, r.(field) = mix(mechanical.(field)(i),mechanical.(field)(j),a); end
        r.wheelSupportForce_N = mix(force(i),force(j),a);
        r.forceResidual_N = r.wheelSupportForce_N-demand;
        r.damperAxialResistance_N = 0; % static, never a viscous supporting force
        r.tangentWheelRate_N_per_m = mix(mechanical.wheelRateTotal_N_per_m(i), ...
            mechanical.wheelRateTotal_N_per_m(j),a);
        rate = r.tangentWheelRate_N_per_m; threshold = options.stiffnessZeroTolerance_N_per_m;
        if ~isfinite(rate)
            r.localStabilityStatus = "STABILITY_NOT_EVALUABLE";
        elseif rate > threshold
            r.localStabilityStatus = "LOCAL_RESTORING";
        elseif rate < -threshold
            r.localStabilityStatus = "LOCAL_NON_RESTORING";
        else
            r.localStabilityStatus = "LOCAL_MARGINAL_OR_DEGENERATE";
        end
        r.stabilityMethod = "VALIDATED_FULL_WHEEL_RATE_AT_SAMPLE";
        if i ~= j, r.stabilityMethod = "INTERPOLATED_VALIDATED_FULL_WHEEL_RATE"; end
        r.springStatus = mechanical.springStatus(i);
        r.damperTravelStatus = mechanical.damperTravelStatus(i);
        r.springSolidStatus = mechanical.springSolidStatus(i);
        if i ~= j && mechanical.springSolidStatus(i) ~= mechanical.springSolidStatus(j)
            r.springSolidStatus = "INTERPOLATED_LIMIT_REPORTING";
        end
        if i ~= j && mechanical.damperTravelStatus(i) ~= mechanical.damperTravelStatus(j)
            r.damperTravelStatus = "INTERPOLATED_LIMIT_REPORTING";
        end
        r.feasibleRelativeToProvidedLimits = true;
        q = mechanical.derivativeDiagnostics;
        eF = model.spring.rate_N_per_m*q.sampleCompressionError_m([i,j]);
        eMR = q.motionRatioAbsoluteError([i,j]);
        error = abs(mechanical.springAxialForce_N([i,j])).*eMR + ...
            abs(mechanical.damperMotionRatio([i,j])).*eF+eF.*eMR;
        r.sampleForceErrorProxy_N = max(error);
        r.interpolationForceErrorProxy_N = 0;
        if i ~= j
            secant = (force(j)-force(i))/(z(j)-z(i));
            rates = mechanical.wheelRateTotal_N_per_m([i,j]);
            if all(isfinite(rates))
                r.interpolationForceErrorProxy_N = max(abs(rates-secant))*abs(z(j)-z(i))/4;
                r.interpolationTravelErrorProxy_m = ...
                    r.interpolationForceErrorProxy_N/abs(secant);
            else
                r.interpolationForceErrorProxy_N = NaN;
            end
        else
            r.interpolationTravelErrorProxy_m = 0;
        end
        if isfinite(r.interpolationForceErrorProxy_N) && isfinite(r.sampleForceErrorProxy_N)
            r.accuracyStatus = "HEURISTIC_ERROR_PROXY_NOT_A_BOUND";
        else
            r.accuracyStatus = "ACCURACY_UNQUANTIFIED";
        end
        r.reportingStatus = "SAMPLED_PATH_ESTIMATE_NOT_SOLVED_POSE";
    end
end

function y = mix(x1,x2,a)
if a == 0
    y = x1;
elseif a == 1
    y = x2;
else
    y = (1-a)*x1+a*x2;
end
end

function r = rootTemplate()
r = struct("equilibriumWheelTravel_m",NaN,"springCompression_m",NaN, ...
    "springAxialForce_N",NaN,"damperLength_m",NaN,"damperMotionRatio",NaN, ...
    "wheelSupportForce_N",NaN,"forceResidual_N",NaN,"tangentWheelRate_N_per_m",NaN, ...
    "damperAxialResistance_N",NaN,"localStabilityStatus","UNAVAILABLE", ...
    "stabilityMethod","UNAVAILABLE","springStatus","UNAVAILABLE", ...
    "damperTravelStatus","UNAVAILABLE","springSolidStatus","UNAVAILABLE", ...
    "feasibleRelativeToProvidedLimits",false,"bracketIndices",[NaN,NaN], ...
    "interpolationFraction",NaN,"method","UNAVAILABLE", ...
    "sampleForceErrorProxy_N",NaN,"interpolationForceErrorProxy_N",NaN, ...
    "interpolationTravelErrorProxy_m",NaN,"accuracyStatus","UNAVAILABLE","reportingStatus","UNAVAILABLE");
end
