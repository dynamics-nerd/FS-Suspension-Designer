function check = checkParametricSeedBump(seed,plan)
%CHECKPARAMETRICSEEDBUMP Explicit sampled native solve; never called by readiness.
fsd.construction.validateParametricSeedResult(seed);
projectRequire(seed.nominalStatus=="VALID",'Native BUMP requires a valid nominal seed.');
plan=seedBumpPlan(plan); sources=cell(numel(seed.geometries),1);
for j=1:numel(sources)
    g=seed.geometries{j}; sweep=fsd.kinematics.solveBumpSweep(g,plan.travel_m,'m',plan.solverOptions);
    sources{j}=seedBumpSource(g,sweep,plan);
end
check=seedBumpCheckCore(seed,plan,sources);
end
