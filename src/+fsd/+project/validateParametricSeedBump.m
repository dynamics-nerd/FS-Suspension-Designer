function valid = validateParametricSeedBump(check,seed)
%VALIDATEPARAMETRICSEEDBUMP Algebraic native replay, retaining gaps/quality/timers.
fsd.construction.validateParametricSeedResult(seed);
projectRequire(isstruct(check) && isscalar(check),'Seed BUMP record required.');
expected=seedBumpCheckCore(seed,seedBumpPlan(check.plan),check.sources);
projectRequire(isequaln(workflowComparable(check),workflowComparable(expected)), 'Seed BUMP evidence/plan/quality association mismatch.');
valid=true;
end
