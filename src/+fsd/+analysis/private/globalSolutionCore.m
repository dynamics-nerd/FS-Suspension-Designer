function solution = globalSolutionCore(p, q, o)
%GLOBALSOLUTIONCORE Acceptance from reconstructed physics, independently of exitflag.
state = globalStateCore(p,q);
budgets = [o.forceTolerance_N;o.momentTolerance_Nm;o.momentTolerance_Nm; ...
    repmat(o.forceTolerance_N,4,1)];
converged = state.feasible && all(isfinite(state.residual)) && ...
    all(abs(state.residual) <= budgets) && abs(state.worldForceResidual_N) <= o.forceTolerance_N && ...
    all(abs(state.worldMomentResidual_Nm(1:2)) <= o.momentTolerance_Nm);
contactResolved = true;
for i = 1:4
    tire = state.corners{i}.tire;
    if isempty(fieldnames(tire)) || tire.contactStatus == "CONTACT_NUMERICALLY_UNRESOLVED"
        contactResolved = false;
    end
end
boundary = any(q <= o.bounds(:,1)+coordinateTolerance(o)) || ...
    any(q >= o.bounds(:,2)-coordinateTolerance(o));
converged = converged && contactResolved && ~boundary;
status = "GLOBAL_STATIC_EQUILIBRIUM_NOT_CONVERGED";
if ~state.feasible, status = "INVALID_PATH_OR_MECHANICAL_LIMIT";
elseif ~contactResolved, status = "CONTACT_NUMERICALLY_UNRESOLVED";
elseif boundary, status = "ARTIFICIAL_SEARCH_BOUNDARY";
elseif converged, status = "GLOBAL_STATIC_EQUILIBRIUM_CONVERGED";
end
H = diag(o.coordinateScales)*state.candidateHessian*diag(o.coordinateScales);
stability = "STABILITY_NOT_EVALUABLE"; eigenvalues = nan(7,1);
if converged && state.bilateralHessianAvailable && all(isfinite(H),"all")
    eigenvalues = eig((H+H')/2);
    if min(eigenvalues) > o.stabilityTolerance_J
        stability = "LOCAL_STABLE_MINIMUM";
    elseif min(eigenvalues) < -o.stabilityTolerance_J
        stability = "NON_RESTORING_STATIONARY_POINT";
    else
        stability = "MARGINAL_OR_DEGENERATE";
    end
end
[J,~] = globalJacobian(p,q,o,state);
scaled = diag(o.coordinateScales)*J*diag(o.coordinateScales);
condition = NaN;
if all(isfinite(scaled),"all"), condition = rcond(scaled); end
solution = struct("state",state,"converged",converged,"status",status, ...
    "stability",stability,"scaledHessianEigenvalues_J",eigenvalues, ...
    "jacobianReciprocalCondition",condition, ...
    "isIllConditioned",~isfinite(condition) || condition <= o.conditioningThreshold);
end

function t = coordinateTolerance(o)
t = repmat(o.positionTolerance_m,7,1); t(2:3) = o.angleTolerance_rad;
end
