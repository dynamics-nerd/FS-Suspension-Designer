function report = verifyV11()
%VERIFYV11 Eleven examples, full Analyzer/DAG, warmed costs and no hidden solves.
% Run setupProject; runProjectTests separately. No commits or output-file writes.
root = fileparts(fileparts(mfilename("fullpath"))); oldPath = path;
cleanup = onCleanup(@() path(oldPath)); addpath(root,fullfile(root,"src"),fullfile(root,"examples"));
assert(fsd.version == "0.11.0");
historical = verifyV08(); % eight examples, all .m Analyzer, DAG, v0.8 integrity/profile
extra = ["vehicleStaticEquilibriumExample","globalStaticEquilibriumExample","designTargetEvaluationExample"];
outputs = cell(3,1);
for i = 1:3
    outputs{i} = feval(extra(i),false); fprintf("EXAMPLE_OK=%s\n",extra(i));
end
e = outputs{3}; spec = e.specification; candidate = e.candidates{1};
single = spec.definitionSI.targets.definitionSI.targets{1}; d = single.definitionSI; d.metadata = single.metadata;
d.type = "POINT_TARGET"; d.x = 0; d.value = d.value(1); d.tolerance = d.tolerance(1);
single = fsd.model.createDesignTarget(d,"rad","m");
scalarSpec = fsd.model.createDesignSpecification(struct("id","SCALAR_BENCHMARK", ...
    "targets",fsd.model.createSuspensionDesignTargets({single})));
definition = spec.definitionSI; definition.metadata = spec.metadata; times = zeros(3,7);
assessment = fsd.analysis.evaluateDesignCandidate(spec,candidate);
for i = 1:4
    timer = tic; fsd.model.createDesignSpecification(definition); creation = toc(timer);
    timer = tic; fsd.model.validateDesignSpecification(spec); validation = toc(timer);
    timer = tic; fsd.analysis.evaluateDesignCandidate(scalarSpec,candidate); scalar = toc(timer);
    timer = tic; fsd.analysis.evaluateDesignCandidate(spec,candidate); curves = toc(timer);
    timer = tic; fsd.analysis.compareDesignCandidates(spec,e.candidates); comparison = toc(timer);
    timer = tic; fsd.analysis.designAssessmentTable(assessment,spec,candidate); reporting = toc(timer);
    timer = tic; fsd.kinematics.solveBumpSweep(candidate.definitionSI.geometries{1}, ...
        candidate.definitionSI.sources{1}.sweep.requestedWheelTravel_m,"m"); sourceSolve = toc(timer);
    if i > 1, times(i-1,:) = [creation,validation,scalar,curves,comparison,reporting,sourceSolve]; end
end
[coreTime,coreProfile] = designCoreBenchmark(spec,candidate);
profile clear; profile on; fsd.analysis.evaluateDesignCandidate(spec,candidate); profile off;
info = profile("info"); names = string({info.FunctionTable.FunctionName});
forbidden = ["solveBump","solveSteering","solveRackSweep","solveAxleRoll","solveActuation", ...
    "solveGlobalStatic","solveCornerStatic","fsolve","fzero","lsqnonlin"];
assert(~any(contains(names,forbidden)),"Evaluation may reconstruct integrity, but cannot execute solvers.");
preparation = info.FunctionTable(contains(names,"designPrepareCandidate"));
assert(isscalar(preparation) && preparation.NumCalls == 1,"One source-preparation pass per evaluation required.");
oldVisible = get(groot,"DefaultFigureVisible");
restore = onCleanup(@() set(groot,"DefaultFigureVisible",oldVisible)); set(groot,"DefaultFigureVisible","off");
figures = fsd.analysis.plotDesignTargetEvaluation(spec,e.candidates); close(figures);
report = struct("matlabRelease",string(version("-release")),"version",fsd.version, ...
    "exampleNames",[historical.exampleNames,extra],"exampleCount",11, ...
    "analyzerFileCount",historical.analyzerFileCount,"analyzerIssueCount",historical.analyzerIssueCount, ...
    "moduleDependencies",historical.moduleDependencies,"sampleCount",9,"medianWallTime_s",median(times,1), ...
    "medianComparisonCore_s",coreTime,"historicalSolverMedian_s",historical.medianWallTime_s(1), ...
    "evaluationSolverCalls",0,"profiledEvaluationFunctions",names,"profiledCoreFunctions",coreProfile, ...
    "newPlotCount",numel(figures));
fprintf("V11_PERFORMANCE_s [create validate scalar curves compare report bumpSolve9]=%.6f %.6f %.6f %.6f %.6f %.6f %.6f\n",report.medianWallTime_s);
fprintf("V11_COMPARISON_CORE_s=%.6f; HISTORICAL_SOLVER_21samples_s=%.6f\n",coreTime,report.historicalSolverMedian_s);
fprintf("V11_EXAMPLES=11/11; PLOTS=%d; EVALUATION_SOLVER_CALLS=0\n",report.newPlotCount);
end
