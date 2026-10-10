function report = verifyV11Audit()
%VERIFYV11AUDIT Eleven examples/Analyzer/DAG/profile plus audit costs and visual QA.
% Generated PNGs stay in ignored output/v0.11-audit-qa, never source code.
root = fileparts(fileparts(mfilename("fullpath"))); oldPath = path;
pathCleanup = onCleanup(@() path(oldPath)); addpath(fullfile(root,"examples"));
base = verifyV11();
e = designTargetEvaluationExample(false); c = e.candidates{1}; spec = e.specification;
target = designTargetFixture("POINT_TARGET","MOTION_RATIO",struct("value",.5,"tolerance",.001));
scalarSpec = designSpecificationFixture(target);
assessment = fsd.analysis.evaluateDesignCandidate(spec,c);
oldVisible = get(groot,"DefaultFigureVisible");
cleanup = onCleanup(@() set(groot,"DefaultFigureVisible",oldVisible));
set(groot,"DefaultFigureVisible","off");
times = zeros(3,5);
for i = 1:4
    timer = tic; fsd.analysis.validateDesignCandidate(c); prepare = toc(timer);
    timer = tic; fsd.analysis.evaluateDesignCandidate(scalarSpec,c); scalar = toc(timer);
    timer = tic; fsd.analysis.evaluateDesignCandidate(spec,c); curve = toc(timer);
    timer = tic; fsd.analysis.validateDesignAssessment(assessment,spec,c); validation = toc(timer);
    timer = tic; figures = fsd.analysis.plotDesignTargetEvaluation(spec,e.candidates); graphics = toc(timer); close(figures);
    if i > 1, times(i-1,:) = [prepare,scalar,curve,validation,graphics]; end
end
identityTime = designAuditTestCall("BENCHMARK_ASSOCIATIONS",[],c);
counts = [1;2;4;8;16]; growth = zeros(numel(counts),2);
for i = 1:numel(counts)
    sources = repmat(c.definitionSI.sources(1),counts(i),1);
    for j = 1:counts(i), sources{j}.id = "REPEATED_SAME_PHYSICS_"+j; end
    many = fsd.model.createDesignCandidate(struct("id","GROWTH_TEST","sources",{sources}));
    fsd.analysis.validateDesignCandidate(many); % warm-up; all native sources verified
    costs = zeros(3,1);
    for j = 1:3, timer = tic; fsd.analysis.validateDesignCandidate(many); costs(j) = toc(timer); end
    growth(i,:) = [median(costs),designAuditTestCall("BENCHMARK_ASSOCIATIONS",[],many)];
end
profile clear; profile on; fsd.analysis.evaluateDesignCandidate(spec,c); profile off;
info = profile("info"); names = string({info.FunctionTable.FunctionName});
forbidden = ["solveBump","solveSteering","solveRackSweep","solveAxleRoll", ...
    "solveActuation","solveGlobalStatic","solveCornerStatic","fsolve","fzero","lsqnonlin"];
assert(~any(contains(names,forbidden)),"No hidden engineering solves allowed.");
entries = info.FunctionTable(endsWith(names,"designCandidateAssociations"));
assert(isscalar(entries) && entries.NumCalls == 1,"One association pass per evaluation required.");
qa = fullfile(root,"output","v0.11-audit-qa"); if ~isfolder(qa), mkdir(qa); end
figures = fsd.analysis.plotDesignTargetEvaluation(spec,e.candidates);
paths = strings(numel(figures)+1,1);
for i = 1:numel(figures)
    set(figures(i),"Position",[100,100,1300,800]);
    paths(i) = string(fullfile(qa,"example-target-"+i+".png"));
    exportgraphics(figures(i),paths(i),"Resolution",120);
end
close(figures);
peak = designTargetFixture("CURVE_TARGET","DAMPER_COMPRESSION", ...
    struct("x",[-.01;0;.01],"value",[0;.005;0],"tolerance",.001));
fig = fsd.analysis.plotDesignTargetEvaluation(designSpecificationFixture(peak),designEvaluationFixture([-.01;.01],[0;0]));
set(fig,"Position",[100,100,1300,800]); paths(end) = string(fullfile(qa,"five-mm-peak.png"));
exportgraphics(fig,paths(end),"Resolution",120); close(fig);
report = struct("baselineVerifier",base,"medianWallTime_s",median(times,1), ...
    "identityComparison_s",identityTime,"sourceCounts",counts,"growth_s",growth, ...
    "evaluationSolverCalls",0,"associationPassesPerEvaluation",entries.NumCalls,"visualQaPaths",paths);
fprintf("AUDIT_COST_s [prepare scalar curve assessmentValidator graphics4]=%.6f %.6f %.6f %.6f %.6f\n",report.medianWallTime_s);
fprintf("AUDIT_IDENTITY_COMPARISON_s=%.6f\n",identityTime);
disp(table(counts,growth(:,1),growth(:,2),VariableNames=["Sources","Prepare_s","Associations_s"]));
fprintf("AUDIT_ASSOCIATION_PASSES=1; HIDDEN_SOLVES=0; QA_PNGS=%d\n",numel(paths));
end
