function report = verifyF01V10()
%VERIFYF01V10 Observational singleton reproductions, before or after correction.
% Run from tests (on the path); fixtures remain private, never added to path.
categories = ["LOCAL_STABLE_MINIMUM","NON_RESTORING_STATIONARY_POINT", ...
    "MARGINAL_OR_DEGENERATE","STABILITY_NOT_EVALUABLE"];
results = cell(4,1);
for i = 1:4
    [s,o,q] = globalSelectionFixture(categories(i));
    r = fsd.analysis.solveGlobalStaticEquilibrium(s,q,o);
    assert(isscalar(r.alternatives));
    a = r.alternatives{1}; assert(a.stability == categories(i));
    assert(fsd.analysis.validateGlobalStaticEquilibrium(r,s));
    fprintf("F01_SINGLETON=%s selected=%g minEigen_J=%.12g U_J=%.12g\n", ...
        a.stability,r.selectedIndex,min(a.scaledHessianEigenvalues_J),a.state.potentialEnergy_J);
    if i == 4
        fprintf("F01_BOUNDARY=%s\n",a.state.corners{1}.bounds.springSolidStatus);
        assert(a.state.corners{1}.bounds.springSolidStatus == "COIL_BIND_LIMIT");
    end
    results{i} = r;
end
% Isolated selector profiling: no physics, factories or solves are available
% in these minimal payloads. Full timing includes unchanged O(A^2) dedup;
% policy filtering/minimum uses three linear passes, not another solve.
counts = [1;10;100]; times = zeros(3,1);
o = struct("selection","LOWEST_ENERGY_STABLE","positionTolerance_m",1e-9,"angleTolerance_rad",1e-9);
for j = 1:numel(counts)
    attempts = cell(counts(j),1);
    for k = 1:counts(j)
        attempts{k} = struct("solution",struct("converged",true,"stability","LOCAL_STABLE_MINIMUM", ...
            "state",struct("q",[k;zeros(6,1)],"potentialEnergy_J",k)));
    end
    globalSelectionTestCall(attempts,o); % warm-up
    samples = zeros(3,1);
    for k = 1:3
        timer = tic; [~,selected] = globalSelectionTestCall(attempts,o); samples(k) = toc(timer);
        assert(selected == 1);
    end
    times(j) = median(samples);
end
profile clear; profile on;
globalSelectionTestCall(attempts,o);
profile off; info = profile("info");
names = string({info.FunctionTable.FunctionName});
assert(~any(contains(names,["fsolve","solveBump","solveActuation","prepareGlobal", ...
    "validateGlobal","createGlobal","globalStateCore","globalSolveCore","globalJacobian"])));
fprintf("F01_SELECTOR_WITH_EXISTING_DEDUP n=%d median_s=%.9g\n",[counts,times]');
fprintf("F01_SELECTION_PHYSICS_CALLS=0; policy O(A); unchanged dedup O(A^2) worst case\n");
report = struct("categories",categories,"results",{results}, ...
    "selectionAlternativeCounts",counts,"medianSelectionIncludingDedup_s",times);
end
