function report = verifyV14F01()
%VERIFYV14F01 Fourteen examples and a real RACK-only audit benchmark.
root=fileparts(fileparts(mfilename('fullpath'))); old=path;
visible=get(groot,'DefaultFigureVisible'); cleanup=onCleanup(@() restore(old,visible));
addpath(root,fullfile(root,'src'),fullfile(root,'examples'));
set(groot,'DefaultFigureVisible','off'); assert(fsd.version()=="0.14.0");
historical=verifyV08();
extra=["vehicleStaticEquilibriumExample","globalStaticEquilibriumExample","designTargetEvaluationExample", ...
    "inverseSuspensionSynthesisExample","axleSuspensionSynthesisExample","steeringSynthesisExample"];
outputs=cell(numel(extra),1);
for j=1:numel(extra), outputs{j}=feval(extra(j),false); fprintf('EXAMPLE_OK=%s\n',extra(j)); end
v12=outputs{4}.result; v13=outputs{5}.result; mixed=outputs{6}.result;
assert(v12.search.evaluationCount==7 && v12.statistics.physicalBumpSweeps==7);
assert(abs(v12.search.records{1}.score-.101722096447)<1e-12 && v12.search.records{v12.selectedIndex}.score==0);
assert(v13.search.evaluationCount==7 && v13.statistics.leftBumpSweeps==7 && ...
    v13.statistics.rightBumpSweeps==7 && v13.statistics.rollSweeps==7);
assert(abs(v13.search.records{1}.score-.0860731195961)<1e-12 && v13.search.records{v13.selectedIndex}.score==0);
assert(mixed.search.evaluationCount==3 && mixed.statistics.leftBumpSweeps==3 && ...
    mixed.statistics.rightBumpSweeps==3 && mixed.statistics.rackSweeps==3);
assert(abs(mixed.search.records{1}.score-.441327900783)<1e-12 && mixed.search.records{mixed.selectedIndex}.score==0);
seed=steeringSynthesisFixture(); d=seed.specification.definitionSI;
targets=d.targets.definitionSI.targets;
targets=targets(cellfun(@(q) q.definitionSI.sourceType=="RACK",targets));
for j=1:numel(targets)
    q=targets{j}.definitionSI; q.tolerance=0;
    targets{j}=fsd.model.createDesignTarget(q,'rad','m');
end
d.targets=fsd.model.createSuspensionDesignTargets(targets); space=rebuildSteeringSpace(seed,d);
rackOnly=fsd.synthesis.runSteeringInverseSearch(space,struct('maxEvaluations',3,'maxIterations',1, ...
    'initialStep',.25,'minimumStep',.25));
assert(rackOnly.search.evaluationCount==3 && rackOnly.statistics.rackSweeps==3);
scores=cellfun(@(e) e.score,rackOnly.search.records);
assert(all(isfinite(scores)) && all(scores>0));
assert(numel(rackOnly.search.records{1}.assessment.targetAssessments)==4);
assert(isequaln(rackOnly.problem.specification.definitionSI,d));
profile clear; profile on;
fsd.synthesis.validateSteeringSynthesisResult(rackOnly);
fsd.analysis.evaluateDesignCandidate(space.specification,rackOnly.search.records{1}.candidate);
fsd.synthesis.compareSteeringSynthesisCandidates(rackOnly,[1;2]);
figures=fsd.synthesis.plotSteeringSynthesisResult(rackOnly,[]);
profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
assert(~any(contains(names,["fsolve","fzero","solveBump","solveRack","solveAxleRoll","solveCornerPath"])));
close(figures); assert(~any(historical.moduleDependencies(:,2)=="synthesis"));
report=struct('version',fsd.version(),'release',string(version('-release')), ...
    'exampleNames',[historical.exampleNames,extra],'exampleCount',14, ...
    'analyzerIssueCount',historical.analyzerIssueCount,'analyzerFileCount',historical.analyzerFileCount, ...
    'moduleDependencies',historical.moduleDependencies,'hiddenSolves',0, ...
    'v12',v12,'v13',v13,'mixed',mixed,'rackOnly',rackOnly,'rackOnlyScores',scores);
save(fullfile(root,'output','v014-f01-verification.mat'),'report');
fprintf('V14_F01 EXAMPLES=14 ANALYZER=%d/%d HIDDEN=0 RACK_ONLY E%d scores=', ...
    report.analyzerIssueCount,report.analyzerFileCount,rackOnly.search.evaluationCount);
fprintf(' %.12g',scores); fprintf(' selected=%d stop=%s\n',rackOnly.selectedIndex,rackOnly.search.stopReason);
end

function restore(old,visible)
path(old); set(groot,'DefaultFigureVisible',visible);
end
