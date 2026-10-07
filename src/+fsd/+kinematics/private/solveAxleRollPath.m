function results = solveAxleRollPath(axle, targets_rad, heave_m, settings)
%SOLVEAXLEROLLPATH Apply canonical heave-first, roll-second continuation.

targets_rad = double(targets_rad(:));
currentDelta_m = 0;
currentPhi_rad = 0;
currentHeave_m = 0;
branchAvailable = true;
pathStats = emptyPathStats();

[state, diagnostic] = solveScalarState(axle, 0, 0, currentDelta_m, ...
    settings, "HEAVE", 0);
pathStats = accumulatePathStats(pathStats, diagnostic);
if state.converged
    currentDelta_m = state.delta_m;
    lastState = state;
else
    branchAvailable = false;
    lastState = state;
    lastDiagnostic = diagnostic;
end

heaveSteps = ceil(abs(heave_m) / ...
    settings.CornerSolverOptions.MaxContinuationStep_m);
for step = 1:heaveSteps
    if ~branchAvailable
        break
    end
    stepHeave_m = heave_m * step / heaveSteps;
    [state, diagnostic] = solveScalarState(axle, 0, stepHeave_m, ...
        currentDelta_m, settings, "HEAVE", step);
    pathStats = accumulatePathStats(pathStats, diagnostic);
    if ~state.converged
        branchAvailable = false;
        lastState = state;
        lastDiagnostic = diagnostic;
        break
    end
    currentDelta_m = state.delta_m;
    currentHeave_m = stepHeave_m;
    lastState = state;
end

cells = cell(numel(targets_rad), 1);
for targetIndex = 1:numel(targets_rad)
    targetPhi_rad = targets_rad(targetIndex);
    if ~branchAvailable
        status = "NOT_ATTEMPTED";
        if targetIndex == 1 && exist("lastDiagnostic", "var")
            status = lastState.status;
            lastDiagnostic.path = pathStats;
            cells{targetIndex} = failureResult(axle, targetPhi_rad, ...
                heave_m, status, lastState.failureReason, lastDiagnostic);
        else
            diagnostic = notAttemptedDiagnostic( ...
                targetPhi_rad, heave_m, settings);
            diagnostic.path = pathStats;
            cells{targetIndex} = failureResult(axle, targetPhi_rad, ...
                heave_m, status, diagnostic.message, diagnostic);
        end
        pathStats = emptyPathStats();
        continue
    end
    increment_rad = targetPhi_rad - currentPhi_rad;
    rollSteps = max(1, ceil(abs(increment_rad) / settings.MaxRollStep_rad));
    targetSucceeded = true;
    for step = 1:rollSteps
        if step == rollSteps
            stepPhi_rad = targetPhi_rad;
        else
            stepPhi_rad = currentPhi_rad + step / rollSteps * increment_rad;
        end
        [state, diagnostic] = solveScalarState(axle, stepPhi_rad, ...
            currentHeave_m, currentDelta_m, settings, "ROLL", step);
        pathStats = accumulatePathStats(pathStats, diagnostic);
        if ~state.converged
            targetSucceeded = false;
            branchAvailable = false;
            break
        end
        currentDelta_m = state.delta_m;
        lastState = state;
    end
    if targetSucceeded
        currentPhi_rad = targetPhi_rad;
        diagnostic.path = pathStats;
        cells{targetIndex} = successResult(axle, targetPhi_rad, ...
            heave_m, lastState, diagnostic);
    else
        diagnostic.path = pathStats;
        cells{targetIndex} = failureResult(axle, targetPhi_rad, ...
            heave_m, state.status, state.failureReason, diagnostic);
    end
    pathStats = emptyPathStats();
end
results = vertcat(cells{:});
end

function [state, diagnostics] = solveScalarState(axle, phi_rad, heave_m, ...
        initialDelta_m, settings, stage, continuationStep)
diagnostics = baseDiagnostics(phi_rad, heave_m, initialDelta_m, ...
    stage, continuationStep, settings);
cacheDelta = zeros(0,1);
cacheResidual = zeros(0,1);
cacheEvaluation = cell(0,1);
validDelta = zeros(0,1);
validResidual = zeros(0,1);
validEvaluation = cell(0,1);

    function residual_m = objective(delta_m)
        [residual_m, ~] = evaluate(delta_m);
    end

    function [residual_m, evaluation] = evaluate(delta_m)
        diagnostics.objectiveRequests = diagnostics.objectiveRequests + 1;
        cached = find(cacheDelta == delta_m, 1);
        if ~isempty(cached)
            diagnostics.cacheHits = diagnostics.cacheHits + 1;
            residual_m = cacheResidual(cached);
            evaluation = cacheEvaluation{cached};
            return
        end
        diagnostics.kinematicEvaluations = ...
            diagnostics.kinematicEvaluations + 1;
        wheelTravel_m = [heave_m + delta_m, heave_m - delta_m];
        axleResult = solveAxleTravelCore( ...
            axle, wheelTravel_m, settings.CornerSolverOptions);
        evaluation = evaluationFromAxle(axle, axleResult, phi_rad, delta_m);
        residual_m = evaluation.residual_m;
        cacheDelta(end+1,1) = delta_m;
        cacheResidual(end+1,1) = residual_m;
        cacheEvaluation{end+1,1} = evaluation;
        diagnostics.lastLeftStatus = string(axleResult.leftResult.status);
        diagnostics.lastRightStatus = string(axleResult.rightResult.status);
        if evaluation.valid
            diagnostics.validEvaluationCount = ...
                diagnostics.validEvaluationCount + 1;
        else
            diagnostics.invalidEvaluationCount = ...
                diagnostics.invalidEvaluationCount + 1;
        end
    end

    function remember(evaluation)
        if ~evaluation.valid || any(validDelta == evaluation.delta_m)
            return
        end
        validDelta(end+1,1) = evaluation.delta_m;
        validResidual(end+1,1) = evaluation.residual_m;
        validEvaluation{end+1,1} = evaluation;
    end

[centerResidual, center] = evaluate(initialDelta_m);
if ~center.valid
    [state, diagnostics] = failedState(center.status, center.diagnostic, ...
        diagnostics, center);
    return
end
remember(center);
if abs(centerResidual) <= settings.RollResidualTolerance_m && ...
        abs(center.roadAngleError_rad) <= settings.RollAngleTolerance_rad
    state = acceptedState(center);
    diagnostics.residual_m = centerResidual;
    diagnostics.message = "Initial scalar state satisfied road closure.";
    return
end

bracketFound = false;
bracket = [NaN, NaN];
lastValid = {center, center};
sideActive = [true, true];
bracketTimer = tic;
for expansion = 0:(settings.MaxBracketExpansions-1)
    halfWidth_m = settings.InitialBracketHalfWidth_m * 2^expansion;
    diagnostics.bracketExpansions = expansion + 1;
    candidates_m = initialDelta_m + [-halfWidth_m, halfWidth_m];
    needsRefinement = [false, false];
    invalidDelta_m = [NaN, NaN];
    for directionIndex = 1:2
        if ~sideActive(directionIndex)
            continue
        end
        [~, candidate] = evaluate(candidates_m(directionIndex));
        if candidate.valid
            remember(candidate);
            lastValid{directionIndex} = candidate;
        else
            needsRefinement(directionIndex) = true;
            invalidDelta_m(directionIndex) = candidates_m(directionIndex);
            sideActive(directionIndex) = false;
            if directionIndex == 1
                diagnostics.negativeBoundaryEncountered = true;
                diagnostics.negativeBoundaryExpansion = expansion + 1;
            else
                diagnostics.positiveBoundaryEncountered = true;
                diagnostics.positiveBoundaryExpansion = expansion + 1;
            end
        end
    end
    exact = selectExactSample(validEvaluation, initialDelta_m, settings);
    if ~isempty(exact)
        diagnostics.bracketElapsedTime_s = toc(bracketTimer);
        diagnostics.bracket_m = [exact.delta_m, exact.delta_m];
        diagnostics.residual_m = exact.residual_m;
        diagnostics.message = "A sampled state satisfied road closure.";
        state = acceptedState(exact);
        return
    end
    [bracketFound, bracket] = selectBracket( ...
        validDelta, validResidual, initialDelta_m);
    if bracketFound
        break
    end
    for refinement = 1:settings.MaxBoundaryRefinements
        refined = false;
        for directionIndex = 1:2
            if ~needsRefinement(directionIndex) || ...
                    abs(invalidDelta_m(directionIndex) - ...
                    lastValid{directionIndex}.delta_m) <= ...
                    settings.BoundaryRefinementTolerance_m
                continue
            end
            midpoint_m = 0.5*(lastValid{directionIndex}.delta_m + ...
                invalidDelta_m(directionIndex));
            [~, midpoint] = evaluate(midpoint_m);
            diagnostics.boundaryRefinements = ...
                diagnostics.boundaryRefinements + 1;
            refined = true;
            if midpoint.valid
                remember(midpoint);
                lastValid{directionIndex} = midpoint;
            else
                invalidDelta_m(directionIndex) = midpoint_m;
            end
        end
        exact = selectExactSample(validEvaluation, initialDelta_m, settings);
        if ~isempty(exact)
            diagnostics.bracketElapsedTime_s = toc(bracketTimer);
            diagnostics.bracket_m = [exact.delta_m, exact.delta_m];
            diagnostics.residual_m = exact.residual_m;
            diagnostics.message = "A boundary sample satisfied road closure.";
            state = acceptedState(exact);
            return
        end
        [bracketFound, bracket] = selectBracket( ...
            validDelta, validResidual, initialDelta_m);
        if bracketFound || ~refined
            break
        end
    end
    if bracketFound
        break
    end
    if ~any(sideActive)
        break
    end
end
diagnostics.bracketElapsedTime_s = toc(bracketTimer);
if ~bracketFound
    diagnostics.bracket_m = [min(validDelta), max(validDelta)];
    if numel(validDelta) <= 1 && diagnostics.invalidEvaluationCount > 0
        status = "KINEMATIC_NONCONVERGENCE";
        diagnostic = "Kinematics did not provide enough valid domain to bracket closure.";
    else
        status = "ROOT_NOT_BRACKETED";
        diagnostic = "Valid states were found but no local closure root was bracketed.";
    end
    [state, diagnostics] = failedState(status, diagnostic, ...
        diagnostics, closestEvaluation(validEvaluation, initialDelta_m));
    return
end
diagnostics.bracket_m = bracket;

rootOptions = optimset("Display", "off", ...
    "TolX", settings.RootStepTolerance_m, ...
    "MaxIter", settings.MaxRootIterations, ...
    "MaxFunEvals", settings.MaxRootEvaluations);
rootTimer = tic;
try
    [root_m, ~, exitFlag, output] = fzero( ...
        @objective, diagnostics.bracket_m, rootOptions);
catch cause
    diagnostics.rootElapsedTime_s = toc(rootTimer);
    diagnostics.message = "Scalar root solver failed: " + string(cause.message);
    [state, diagnostics] = failedState("SCALAR_NO_CONVERGENCE", ...
        diagnostics.message, diagnostics, center);
    return
end
diagnostics.rootElapsedTime_s = toc(rootTimer);
diagnostics.rootIterations = output.iterations;
diagnostics.rootFunctionEvaluations = output.funcCount;
diagnostics.rootExitFlag = exitFlag;
[residual_m, final] = evaluate(root_m);
diagnostics.residual_m = residual_m;
if exitFlag <= 0 || ~final.valid || ...
        abs(residual_m) > settings.RollResidualTolerance_m || ...
        abs(final.roadAngleError_rad) > settings.RollAngleTolerance_rad
    [state, diagnostics] = failedState("SCALAR_NO_CONVERGENCE", ...
        "Scalar root did not satisfy road closure tolerances.", ...
        diagnostics, final);
    return
end
state = acceptedState(final);
diagnostics.message = string(output.message);
end

function evaluation = evaluationFromAxle(axle, axleResult, phi_rad, delta_m)
evaluation = invalidEvaluation(delta_m, "KINEMATIC_NONCONVERGENCE", ...
    axleResult.failureReason);
evaluation.axleTravelResult = axleResult;
if ~axleResult.converged
    return
end
leftContact = contact(axle.leftGeometry, axleResult.leftResult);
rightContact = contact(axle.rightGeometry, axleResult.rightResult);
if string(leftContact.status) ~= "FINITE" || ...
        string(rightContact.status) ~= "FINITE"
    evaluation.status = "CONTACT_DEGENERATE";
    evaluation.diagnostic = "A geometric wheel contact is undefined.";
    return
end
solvedLine = fsd.geometry.roadLineFromContacts( ...
    leftContact.point_m, rightContact.point_m);
if string(solvedLine.status) ~= "FINITE"
    evaluation.status = string(solvedLine.status);
    evaluation.diagnostic = string(solvedLine.diagnostic);
    return
end
frame = fsd.geometry.bodyRollRoadFrame(phi_rad);
residual_m = fsd.geometry.roadClosureResidual( ...
    phi_rad, leftContact.point_m, rightContact.point_m);
reference_yz_m = 0.5 * (leftContact.point_m(2:3) + ...
    rightContact.point_m(2:3));
targetLine = fsd.geometry.roadLineFromBodyRoll(phi_rad, reference_yz_m);
crossValue = frame.direction_yz(1) * solvedLine.direction_yz(2) - ...
    frame.direction_yz(2) * solvedLine.direction_yz(1);
angleError_rad = atan2(crossValue, ...
    dot(frame.direction_yz, solvedLine.direction_yz));
evaluation = struct( ...
    "valid", true, "converged", true, "status", "CONVERGED", ...
    "failureReason", "", "diagnostic", "", "delta_m", delta_m, ...
    "residual_m", residual_m, "roadAngleError_rad", angleError_rad, ...
    "axleTravelResult", axleResult, "leftContact", leftContact, ...
    "rightContact", rightContact, "roadFrame", frame, ...
    "targetRoadLine", targetLine, "solvedRoadLine", solvedLine);
end

function value = contact(geometry, result)
center = fsd.model.getPoint(geometry, ...
    string(geometry.cornerId) + "_WHEEL_CENTER");
datum = fsd.model.getPoint(geometry, ...
    string(geometry.cornerId) + "_CONTACT_PATCH");
radius_m = norm(datum - center);
ideal = fsd.geometry.geometricWheelContact( ...
    result.state.wheelCenter_m, result.wheelAxis, radius_m);
value = struct("status", string(ideal.status), ...
    "point_m", double(ideal.point_m), "geometricRadius_m", radius_m, ...
    "diagnostic", string(ideal.diagnostic));
end

function state = acceptedState(evaluation)
state = evaluation;
state.converged = true;
state.status = "CONVERGED";
state.failureReason = "";
end

function [state, diagnostics] = failedState(status, reason, diagnostics, last)
state = invalidEvaluation(NaN, status, reason);
state.axleTravelResult = last.axleTravelResult;
diagnostics.residual_m = last.residual_m;
diagnostics.message = string(reason);
end

function value = invalidEvaluation(delta_m, status, diagnostic)
value = struct( ...
    "valid", false, "converged", false, "status", string(status), ...
    "failureReason", string(diagnostic), "diagnostic", string(diagnostic), ...
    "delta_m", delta_m, "residual_m", NaN, ...
    "roadAngleError_rad", NaN, "axleTravelResult", struct(), ...
    "leftContact", invalidContact(diagnostic), ...
    "rightContact", invalidContact(diagnostic), ...
    "roadFrame", struct(), "targetRoadLine", struct(), ...
    "solvedRoadLine", struct());
end

function value = invalidContact(diagnostic)
value = struct("status", "KINEMATICS_NOT_CONVERGED", ...
    "point_m", [NaN, NaN, NaN], "geometricRadius_m", NaN, ...
    "diagnostic", string(diagnostic));
end

function selected = selectExactSample(samples, center_m, settings)
selected = [];
if isempty(samples)
    return
end
isRoot = cellfun(@(sample) ...
    abs(sample.residual_m) <= settings.RollResidualTolerance_m && ...
    abs(sample.roadAngleError_rad) <= settings.RollAngleTolerance_rad, ...
    samples);
candidates = find(isRoot);
if isempty(candidates)
    return
end
distance = cellfun(@(sample) abs(sample.delta_m-center_m), ...
    samples(candidates));
[~, nearest] = min(distance);
selected = samples{candidates(nearest)};
end

function [found, bracket] = selectBracket(delta_m, residual_m, center_m)
found = false;
bracket = [NaN, NaN];
if numel(delta_m) < 2
    return
end
[sortedDelta, order] = sort(delta_m);
sortedResidual = residual_m(order);
candidates = zeros(0,5);
for index = 1:(numel(sortedDelta)-1)
    if sortedResidual(index)*sortedResidual(index+1) > 0
        continue
    end
    interval = sortedDelta(index:index+1).';
    distance = max([interval(1)-center_m, center_m-interval(2), 0]);
    midpointDistance = abs(mean(interval)-center_m);
    candidates(end+1,:) = [distance, midpointDistance, ...
        diff(interval), interval]; %#ok<AGROW>
end
if isempty(candidates)
    return
end
candidates = sortrows(candidates, [1,2,3,4]);
bracket = candidates(1,4:5);
found = true;
end

function selected = closestEvaluation(samples, center_m)
distance = cellfun(@(sample) abs(sample.delta_m-center_m), samples);
[~, index] = min(distance);
selected = samples{index};
end

function diagnostics = baseDiagnostics(phi_rad, heave_m, delta_m, stage, ...
        step, settings)
diagnostics = struct( ...
    "solver", "fzero", "attempted", true, "stage", string(stage), ...
    "continuationStep", step, "attemptedBodyRollAngle_rad", phi_rad, ...
    "attemptedAxleHeave_m", heave_m, "initialDelta_m", delta_m, ...
    "bracket_m", [NaN, NaN], "bracketExpansions", 0, ...
    "rootIterations", 0, "rootFunctionEvaluations", 0, ...
    "rootExitFlag", 0, "kinematicEvaluations", 0, ...
    "objectiveRequests", 0, "cacheHits", 0, ...
    "validEvaluationCount", 0, "invalidEvaluationCount", 0, ...
    "boundaryRefinements", 0, "bracketElapsedTime_s", 0, ...
    "rootElapsedTime_s", 0, ...
    "negativeBoundaryEncountered", false, ...
    "positiveBoundaryEncountered", false, ...
    "negativeBoundaryExpansion", 0, "positiveBoundaryExpansion", 0, ...
    "bracketSelectionPolicy", "nearest-valid-adjacent-to-previous-root", ...
    "residual_m", NaN, "lastLeftStatus", "", ...
    "lastRightStatus", "", ...
    "residualTolerance_m", settings.RollResidualTolerance_m, ...
    "angleTolerance_rad", settings.RollAngleTolerance_rad, ...
    "message", "", "path", emptyPathStats());
end

function value = emptyPathStats()
value = struct("scalarSolves", 0, "heaveStates", 0, "rollStates", 0, ...
    "uniqueFunctionEvaluations", 0, "cornerSolves", 0, ...
    "objectiveRequests", 0, "cacheHits", 0, ...
    "boundaryRefinements", 0, "bracketElapsedTime_s", 0, ...
    "rootElapsedTime_s", 0);
end

function total = accumulatePathStats(total, diagnostics)
total.scalarSolves = total.scalarSolves + 1;
if string(diagnostics.stage) == "HEAVE"
    total.heaveStates = total.heaveStates + 1;
else
    total.rollStates = total.rollStates + 1;
end
total.uniqueFunctionEvaluations = total.uniqueFunctionEvaluations + ...
    diagnostics.kinematicEvaluations;
total.cornerSolves = total.cornerSolves + 2*diagnostics.kinematicEvaluations;
total.objectiveRequests = total.objectiveRequests + ...
    diagnostics.objectiveRequests;
total.cacheHits = total.cacheHits + diagnostics.cacheHits;
total.boundaryRefinements = total.boundaryRefinements + ...
    diagnostics.boundaryRefinements;
total.bracketElapsedTime_s = total.bracketElapsedTime_s + ...
    diagnostics.bracketElapsedTime_s;
total.rootElapsedTime_s = total.rootElapsedTime_s + ...
    diagnostics.rootElapsedTime_s;
end

function result = successResult(axle, phi_rad, heave_m, state, diagnostics)
wheelTravel_m = state.axleTravelResult.requestedWheelTravel_m;
result = baseResult(axle, phi_rad, heave_m, wheelTravel_m, ...
    state, true, "CONVERGED", "", diagnostics);
end

function result = failureResult(axle, phi_rad, heave_m, status, reason, diagnostics)
state = invalidEvaluation(NaN, status, reason);
result = baseResult(axle, phi_rad, heave_m, [NaN, NaN], ...
    state, false, status, reason, diagnostics);
end

function result = baseResult(axle, phi_rad, heave_m, wheelTravel_m, ...
        state, converged, status, reason, diagnostics)
result = struct( ...
    "schemaVersion", "0.6.0", "kind", "AxleRollResult", ...
    "axleIdentity", fsd.model.axleIdentity(axle), ...
    "requestedBodyRollAngle_rad", double(phi_rad), ...
    "requestedAxleHeave_m", double(heave_m), ...
    "achievedBodyRollAngle_rad", valueOrNaN(converged, phi_rad), ...
    "achievedAxleHeave_m", valueOrNaN(converged, heave_m), ...
    "wheelTravel_m", wheelTravel_m, ...
    "wheelTravelDifferential_m", differenceOrNaN(wheelTravel_m), ...
    "axleTravelResult", state.axleTravelResult, ...
    "leftGeometricContact", state.leftContact, ...
    "rightGeometricContact", state.rightContact, ...
    "roadFrame", state.roadFrame, ...
    "targetRoadLine", state.targetRoadLine, ...
    "solvedContactRoadLine", state.solvedRoadLine, ...
    "closureResidual_m", state.residual_m, ...
    "roadAngleError_rad", state.roadAngleError_rad, ...
    "converged", logical(converged), "status", string(status), ...
    "failureReason", string(reason), "diagnostics", diagnostics, ...
    "elapsedTime_s", 0);
end

function value = valueOrNaN(condition, input)
value = NaN;
if condition
    value = double(input);
end
end

function value = differenceOrNaN(travel)
value = NaN;
if all(isfinite(travel))
    value = travel(1) - travel(2);
end
end

function diagnostics = notAttemptedDiagnostic(phi_rad, heave_m, settings)
diagnostics = baseDiagnostics(phi_rad, heave_m, NaN, "ROLL", 0, settings);
diagnostics.attempted = false;
diagnostics.message = "Not attempted after an earlier continuation failure.";
end
