function [q, diagnostics] = globalSolveCore(p, initial, o)
%GLOBALSOLVECORE Damped scaled Newton on seven residuals, guarded feasible line search.
timer = tic; q = initial; count = 0; iterations = 0;
reason = "MAX_ITERATIONS"; history = nan(o.maxIterations+1,1);
budgets = [o.forceTolerance_N;o.momentTolerance_Nm;o.momentTolerance_Nm; ...
    repmat(o.forceTolerance_N,4,1)];
for k = 0:o.maxIterations
    state = globalStateCore(p,q); count = count+1;
    normR = norm(state.residual./budgets,inf); history(k+1) = normR;
    if ~state.feasible, reason = "INVALID_INITIAL_OR_PATH"; break; end
    if normR <= 1, reason = "RESIDUAL_BUDGET_SATISFIED"; break; end
    if k == o.maxIterations, break; end
    [J,calls] = globalJacobian(p,q,o,state); count = count+calls;
    scaled = (J.*o.coordinateScales')./budgets;
    if any(~isfinite(scaled),"all"), reason = "JACOBIAN_UNAVAILABLE"; break; end
    if rcond(scaled) <= o.conditioningThreshold
        step = -pinv(scaled)* (state.residual./budgets);
    else
        step = -scaled\(state.residual./budgets);
    end
    step = step.*o.coordinateScales;
    accepted = false; alpha = 1;
    for j = 1:o.maxLineSearchSteps
        candidate = q+alpha*step;
        if all(candidate >= o.bounds(:,1) & candidate <= o.bounds(:,2))
            trial = globalStateCore(p,candidate); count = count+1;
            sameSegments = isequal(cellfun(@(c) c.pathSegmentIndex,trial.corners), ...
                cellfun(@(c) c.pathSegmentIndex,state.corners));
            if trial.feasible && sameSegments && norm(trial.residual./budgets,inf) < normR
                accepted = true; break;
            end
        end
        alpha = alpha/2;
    end
    if ~accepted, reason = "NO_FEASIBLE_RESIDUAL_DECREASE"; break; end
    q = candidate; iterations = iterations+1;
    tolerances = repmat(o.positionTolerance_m,7,1); tolerances(2:3) = o.angleTolerance_rad;
    if all(abs(alpha*step) <= tolerances)
        % A small step alone never certifies an equilibrium.
        trial = globalStateCore(p,q); count = count+1;
        history(k+2) = norm(trial.residual./budgets,inf);
        if all(abs(trial.residual) <= budgets), reason = "RESIDUAL_BUDGET_SATISFIED";
        else, reason = "POSITION_STAGNATION_WITH_RESIDUAL"; end
        break;
    end
end
diagnostics = struct("method","SCALED_DAMPED_NEWTON","termination",reason, ...
    "iterations",iterations,"residualEvaluations",count,"sourceRevalidationsDuringSolve",0, ...
    "scaledResidualHistory",history(1:iterations+1),"solveTime_s",toc(timer));
end
