function report = verifyV09()
%VERIFYV09 Nine examples, Analyzer/DAG, local timings and no hidden solves.
root = fileparts(fileparts(mfilename("fullpath")));
oldPath = path; cleanup = onCleanup(@() path(oldPath));
addpath(root,fullfile(root,"src"),fullfile(root,"tests"),fullfile(root,"examples"));
assert(strcmp(fsd.version,"0.9.0"));
previous = verifyV08; % 8 examples + Analyzer over ALL current .m + module DAG
e = vehicleStaticEquilibriumExample(false); fprintf("EXAMPLE_OK=vehicleStaticEquilibriumExample\n");
fsd.analysis.validateStaticVehicleLoads(e.loads,e.vehicle,e.loadCase);
fsd.analysis.validateCornerStaticEquilibrium(e.equilibrium,e.model,e.actuation,e.mechanical);
times = zeros(3,7);
units = struct("length","m","mass","kg","gravity","m/s^2");
for iteration = 1:4
    timer = tic; v = fsd.model.createVehicleParameters(e.vehicle.definitionSI,units);
    createTime = toc(timer); timer = tic;
    fsd.model.validateVehicleParameters(v); validateTime = toc(timer); timer = tic;
    loads = fsd.analysis.analyzeStaticVehicleLoads(v,e.loadCase);
    loadTime = toc(timer); timer = tic;
    [u,s,basis] = svd(loads.family.scaledMatrixA);
    bs = loads.family.rhs./[1;loads.family.scale_m;loads.family.scale_m];
    representative = basis(:,1:3)*((u'*bs)./diag(s(:,1:3)));
    direction = basis(:,4);
    decompositionTime = toc(timer);
    assert(norm(loads.family.scaledMatrixA*direction) < 1e-12);
    assert(norm(loads.family.scaledMatrixA*representative-bs) < 1e-8);
    timer = tic;
    local = fsd.analysis.solveCornerStaticEquilibrium(e.model,e.actuation,e.mechanical, ...
        e.loads.supportForce_N(1),e.equilibrium.options);
    localTime = toc(timer);
    if iteration > 1
        times(iteration-1,:) = [createTime,validateTime,loadTime,loads.elapsedTime_s, ...
            decompositionTime,localTime,local.elapsedTime_s];
    end
end
integrationTimes = zeros(3,1);
for iteration = 1:4
    timer = tic; vehicleStaticEquilibriumExample(false);
    if iteration > 1, integrationTimes(iteration-1) = toc(timer); end
end
% All geometry solves happened before this profile. These APIs consume results.
profile clear; profile on;
fsd.model.createVehicleParameters(e.vehicle.definitionSI,units);
fsd.analysis.analyzeStaticVehicleLoads(e.vehicle,e.loadCase);
fsd.analysis.solveCornerStaticEquilibrium(e.model,e.actuation,e.mechanical, ...
    e.loads.supportForce_N(1),e.equilibrium.options);
profile off; info = profile("info"); names = string({info.FunctionTable.FunctionName});
assert(~any(contains(names,["fsolve","fzero","solveBump","solveActuation","solveAxleRoll"])), ...
    "Vehicle loads/local equilibrium must not rerun geometry or nonlinear solves.");
report = struct("matlabRelease",string(version("-release")),"exampleCount",9, ...
    "analyzerIssueCount",previous.analyzerIssueCount,"analyzerFileCount",previous.analyzerFileCount, ...
    "moduleDependencies",previous.moduleDependencies,"mechanicalPathSampleCount",numel(e.mechanical.states), ...
    "medianTimes_s",median(times,1),"medianExampleTotalTime_s",median(integrationTimes), ...
    "loadAndEquilibriumNonlinearSolveCount",0,"example",e);
fprintf("V09_TIMES_ms [create validate loadAPI loadCore scaledSVD localAPI localCore]=%.6f %.6f %.6f %.6f %.6f %.6f %.6f\n", ...
    1000*report.medianTimes_s);
fprintf("V09_EXAMPLE_TOTAL_ms=%.6f; states=%d; hidden_solves=0; examples=9/9\n", ...
    1000*report.medianExampleTotalTime_s,report.mechanicalPathSampleCount);
end
