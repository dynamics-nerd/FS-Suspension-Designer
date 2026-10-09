function report = verifyV09Audit()
%VERIFYV09AUDIT Warmed algebra/core timings and specifically profiled flat filter.
% Run setupProject; runProjectTests; verifyV09 for full regression/examples/DAG.
root = fileparts(fileparts(mfilename("fullpath")));
previous = path; cleanup = onCleanup(@() path(previous));
addpath(fullfile(root,"src"));
[v,d,u] = vehicleFixture();
c = fsd.model.createVehicleLoadCase(v,struct("mode","UNDERDETERMINED","sourceKind","DERIVED"));
loadTimes = zeros(3,2);
for iteration = 1:4
    timer = tic; r = fsd.analysis.analyzeStaticVehicleLoads(v,c); elapsed = toc(timer);
    if iteration > 1, loadTimes(iteration-1,:) = [elapsed,r.elapsedTime_s]; end
end
sizes = [21;101;501;2001]; times = zeros(4,3); counts = zeros(4,2);
m = springDamperFixture(0);
for i = 1:numel(sizes)
    z = linspace(-.04,-.01,sizes(i))';
    p = fsd.analysis.analyzePrescribedSpringDamperPath(m,z,.5*z,0, ...
        struct("length","m","velocity","m/s"));
    measurements = zeros(3,3);
    fsd.analysis.solveCornerStaticEquilibrium(m,[],p,0); % warm-up
    for iteration = 1:3
        timer = tic; r = fsd.analysis.solveCornerStaticEquilibrium(m,[],p,0); elapsed = toc(timer);
        % Profile separately: source validation must not hide the filter cost.
        profile clear; profile on;
        fsd.analysis.solveCornerStaticEquilibrium(m,[],p,0);
        profile off; info = profile("info"); names = string({info.FunctionTable.FunctionName});
        index = contains(names,"rootsOutsideFlatIntervals");
        assert(sum(index) == 1,"The specific interval filter must be profiled.");
        measurements(iteration,:) = [elapsed,r.elapsedTime_s,info.FunctionTable(index).TotalTime];
    end
    times(i,:) = median(measurements,1);
    diag = r.flatIntervalFilterDiagnostics;
    counts(i,:) = [diag.rootComparisonCount,diag.intervalAdvanceCount];
    assert(r.rootCount == 0 && sum(counts(i,:)) <= 2*sizes(i));
end
fprintf("AUDIT_LOAD_ms [API core]=%.6f %.6f\n",1000*median(loadTimes,1));
fprintf("AUDIT_FLAT N API_ms core_ms filter_profile_ms root_comparisons interval_advances\n");
fprintf("AUDIT_FLAT N=%d API_ms=%.6f core_ms=%.6f filter_profile_ms=%.6f comparisons=%d advances=%d\n", ...
    [sizes,1000*times,counts]');
xy = [0,-.5;2,.5;1,-.5];
for i = 1:3
    d.cg = [xy(i,:),.3]; v = fsd.model.createVehicleParameters(d,u);
    c = fsd.model.createVehicleLoadCase(v,struct("mode","UNDERDETERMINED","sourceKind","DERIVED"));
    r = fsd.analysis.analyzeStaticVehicleLoads(v,c);
    fprintf("AUDIT_BOUNDARY xy=[%g,%g] feasible=%d lambda=[%.17g,%.17g] budget=%.17gN dimension=%g\n", ...
        xy(i,:),r.family.feasible,r.family.lambdaInterval_N,r.family.lambdaBoundaryBudget_N,r.family.admissibleDimension);
    disp(r.family.endpointLoads_N(:,1)');
end
d.cg = [.4,0,.3]; d.unsprungMass = zeros(1,4); v = fsd.model.createVehicleParameters(d,u);
c = fsd.model.createVehicleLoadCase(v,struct("mode","CROSSWEIGHT_SPECIFIED", ...
    "crossweight",.3-1e-10,"sourceKind","TARGET"));
r = fsd.analysis.analyzeStaticVehicleLoads(v,c);
fprintf("AUDIT_CW requested=%.17g status=%s candidateRL=%.17g roundoff=%.17gN\n", ...
    c.definitionSI.crossweightFraction,r.status,r.candidateCornerLoads_N(3),r.normalRoundoffBudget_N);
report = struct("matlabRelease",string(version("-release")), ...
    "medianLoadTimes_s",median(loadTimes,1),"flatSizes",sizes, ...
    "medianFlatTimes_s",times,"flatStructuralCounts",counts, ...
    "filterTimeMethod","SEPARATE_PROFILER_TOTALTIME","crossweightReproduction",r);
end
