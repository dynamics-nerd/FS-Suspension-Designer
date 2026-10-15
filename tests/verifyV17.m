function report = verifyV17()
%VERIFYV17 Seventeen examples, native regression, no-hidden-work profiles and costs.
root=fileparts(fileparts(mfilename('fullpath'))); old=path; visible=get(groot,'DefaultFigureVisible');
cleanup=onCleanup(@()restore(old,visible));
addpath(root,fullfile(root,'src'),fullfile(root,'examples')); set(groot,'DefaultFigureVisible','off');
assert(fsd.version()=="0.17.0"); historical=verifyV08();
extra=["vehicleStaticEquilibriumExample","globalStaticEquilibriumExample","designTargetEvaluationExample", ...
    "inverseSuspensionSynthesisExample","axleSuspensionSynthesisExample","steeringSynthesisExample", ...
    "actuationSynthesisExample","vehicleConceptProjectExample","conceptToSeedExample"];
outputs=cell(numel(extra),1);
for j=1:numel(extra), outputs{j}=feval(extra(j),false); fprintf('EXAMPLE_OK=%s\n',extra(j)); end
v12=outputs{4}.result; v13=outputs{5}.result; v14=outputs{6}.result; v15=outputs{7}.result; example=outputs{8};
assert(v12.search.evaluationCount==7 && v12.statistics.physicalBumpSweeps==7 && ...
    abs(v12.search.records{1}.score-.101722096447)<1e-12 && v12.search.records{v12.selectedIndex}.score==0);
assert(v13.search.evaluationCount==7 && v13.statistics.leftBumpSweeps==7 && v13.statistics.rightBumpSweeps==7 && ...
    v13.statistics.rollSweeps==7 && abs(v13.search.records{1}.score-.0860731195961)<1e-12 && v13.search.records{v13.selectedIndex}.score==0);
assert(v14.search.evaluationCount==3 && v14.statistics.leftBumpSweeps==3 && v14.statistics.rightBumpSweeps==3 && ...
    v14.statistics.rackSweeps==3 && abs(v14.search.records{1}.score-.441327900783)<1e-12 && v14.search.records{v14.selectedIndex}.score==0);
assert(v15.search.evaluationCount==8 && v15.statistics.bumpSweeps==8 && v15.statistics.actuationSweeps==8 && ...
    v15.statistics.mechanicalAnalyses==8 && abs(v15.search.records{1}.score-.231415023063)<1e-12 && v15.search.records{v15.selectedIndex}.score==0);
legacy=steeringSynthesisFixture(); d=legacy.specification.definitionSI; ts=d.targets.definitionSI.targets;
ts=ts(cellfun(@(q)q.definitionSI.sourceType=="RACK",ts));
for j=1:numel(ts), q=ts{j}.definitionSI; q.tolerance=0; ts{j}=fsd.model.createDesignTarget(q,'rad','m'); end
d.targets=fsd.model.createSuspensionDesignTargets(ts);
rackOnly=fsd.synthesis.runSteeringInverseSearch(rebuildSteeringSpace(legacy,d), ...
    struct('maxEvaluations',3,'maxIterations',1,'initialStep',.25,'minimumStep',.25));
rackScores=cellfun(@(e)e.score,rackOnly.search.records);
assert(rackOnly.statistics.leftBumpSweeps==3 && rackOnly.statistics.rightBumpSweeps==3 && rackOnly.statistics.rackSweeps==3 && ...
    abs(rackScores(1)-.0265716889609)<1e-13 && abs(rackScores(3)-.0238159165073)<1e-13);
% Readiness must not even replay a historical search in a populated result ledger.
fprintf('V17_PHASE=READINESS_PROFILE\n'); profile clear; profile on;
fsd.project.designReadiness(example.project); fsd.project.prepareEngineeringScenario(example.project,'ACT_DESIGN');
profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
assert(~any(contains(names,["fsolve","fzero","solveBump","solveActuation","solveRack","solveAxleRoll","boundedDirectSearch"])));
fprintf('V17_PHASE=CONSUMER_PROFILE\n'); file=fullfile(root,'output','v017-profile-roundtrip.mat');
profile clear; profile on;
fsd.project.validateEngineeringResult(example.result); fsd.project.validateEngineeringProject(example.project);
fsd.project.saveEngineeringProject(example.project,file,true); fsd.project.loadEngineeringProject(file);
profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
assert(~any(contains(names,["fsolve","fzero","solveBump","solveActuation","solveRack","solveAxleRoll"])));
% Use one native evaluation for reproducible wrapper costs, not an arbitrary new benchmark.
p=example.project; d=p.definition; d.results={}; d.derivations={}; scenarios=d.scenarios;
for j=1:numel(scenarios)
    if scenarios{j}.definition.id=="ACT_DESIGN"
        definition=scenarios{j}.definition; definition.options=struct('maxEvaluations',1);
        scenarios{j}=fsd.project.createEngineeringScenario(definition); scenarioDefinition=definition;
    end
end
d.scenarios=scenarios; p=fsd.project.createEngineeringProject(d);
fprintf('V17_PHASE=DELEGATED_PROFILE\n'); profile clear; profile on;
small=fsd.project.runEngineeringScenario(p,'ACT_DESIGN','TIMED_RESULT'); profile off;
info=profile('info'); names=string({info.FunctionTable.FunctionName});
bump=info.FunctionTable(endsWith(names,'solveBumpSweep')); act=info.FunctionTable(endsWith(names,'solveActuationSweep'));
assert(sum([bump.NumCalls])==1 && sum([act.NumCalls])==1 && small.nativePayload.search.evaluationCount==1);
% Warm-up discarded; three uninstrumented samples, no concurrent MATLAB workloads.
[concept,physicalOptions]=conceptWorkflowFixture(); times=zeros(3,8);
fprintf('V17_PHASE=WARMED_TIMING\n'); file=fullfile(root,'output','v017-timing-roundtrip.mat');
for j=1:4
    timer=tic; fsd.project.createVehicleConcept(concept.definitionSI); t1=toc(timer);
    timer=tic; fsd.project.validateVehicleConcept(concept); t2=toc(timer);
    timer=tic; fsd.project.deriveVehicleConcept(concept,physicalOptions); t3=toc(timer);
    timer=tic; fsd.project.designReadiness(p,'ACT_DESIGN'); t4=toc(timer);
    timer=tic; fsd.project.createEngineeringScenario(scenarioDefinition); t5=toc(timer);
    timer=tic; small=fsd.project.runEngineeringScenario(p,'ACT_DESIGN','TIMED_RESULT'); t6=toc(timer);
    timer=tic; fsd.project.validateEngineeringResult(small); t7=toc(timer);
    withResult=fsd.project.attachEngineeringResult(p,small);
    timer=tic; fsd.project.saveEngineeringProject(withResult,file,true); loaded=fsd.project.loadEngineeringProject(file); t8=toc(timer);
    assert(isequaln(withResult,loaded)); if j>1, times(j-1,:)=[t1,t2,t3,t4,t5,t6,t7,t8]; end
end
edges=historical.moduleDependencies;
assert(~any(edges(:,2)=="project") && isdag(digraph(edges(:,1),edges(:,2))));
report=struct('version',fsd.version(),'release',string(version('-release')),'exampleNames',[historical.exampleNames,extra], ...
    'exampleCount',17,'analyzerIssueCount',historical.analyzerIssueCount,'analyzerFileCount',historical.analyzerFileCount, ...
    'moduleDependencies',edges,'hiddenForwardSolves',0,'readinessSearchCalls',0, ...
    'profileBumpSweeps',sum([bump.NumCalls]),'profileActuationSweeps',sum([act.NumCalls]), ...
    'timingSamples_s',times,'medianTimes_s',median(times,1),'timingEvaluationBudget',1, ...
    'v12',v12,'v13',v13,'v14',v14,'v15',v15,'rackOnly',rackOnly,'rackOnlyScores',rackScores,'projectExample',example);

% New construction costs measured separately, after warm-up and without profiling.
seedDemo=outputs{9}; definition=seedDemo.seed.definition; refs=seedDemo.seed.referenceParameters;
fprintf('V17_PHASE=SEED_PROFILE\n'); profile clear; profile on;
fsd.project.designReadiness(seedDemo.project,'BUILD_FRONT');
fsd.project.validateEngineeringResult(seedDemo.physical);
profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
assert(~any(contains(names,["fsolve","fzero","solveBump","solveRack","solveActuation","boundedDirectSearch"])));
% The full ledger includes native synthesis: its historical validator replays
% stored controller records, but must never evaluate another physical candidate.
profile clear; profile on;
fsd.project.validateEngineeringProject(seedDemo.project);
profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
assert(~any(contains(names,["fsolve","fzero","solveBump","solveRack","solveActuation","runInverseSearch","evaluateGeometry"])));
replay=info.FunctionTable(endsWith(names,'boundedDirectSearch'));
report.seedReadinessSearchCalls=0; report.seedHiddenForwardSolves=0;
report.seedConsumerControllerReplayCalls=sum([replay.NumCalls]);
seedTimes=zeros(3,9); file=fullfile(root,'output','v017-seed-timing.mat');
for j=1:4
    timer=tic; fsd.construction.parametricSeedReadiness(definition,refs); a1=toc(timer);
    [~,oneDefinition]=parametricSeedInputs('FL');
    timer=tic; one=fsd.construction.buildParametricSeed(oneDefinition,refs); a2=toc(timer);
    timer=tic; fsd.model.validateDoubleWishboneGeometry(one.geometries{1}); a3=toc(timer);
    timer=tic; pair=fsd.construction.buildParametricSeed(definition,refs); a4=toc(timer);
    timer=tic; fsd.project.checkConceptGeometryConsistency(seedDemo.project.definition.concept,pair.geometries); a5=toc(timer);
    timer=tic; fsd.project.checkParametricSeedBump(pair,struct('travel_m',[-.01;0;.01])); a6=toc(timer);
    timer=tic; adopted=fsd.project.registerParametricSeed(seedDemo.nominal.projectAtExecution,seedDemo.nominal); a7=toc(timer);
    timer=tic; fsd.project.validateEngineeringResult(seedDemo.physical); a8=toc(timer);
    timer=tic; fsd.project.saveEngineeringProject(adopted,file,true); loaded=fsd.project.loadEngineeringProject(file); a9=toc(timer);
    assert(isequaln(loaded,adopted)); if j>1, seedTimes(j-1,:)=[a1,a2,a3,a4,a5,a6,a7,a8,a9]; end
end
report.seedTimingSamples_s=seedTimes; report.seedMedianTimes_s=median(seedTimes,1);
report.seedExample=seedDemo;
fprintf('V17_SEED_MEDIAN_s [inputs corner nativeValidation pair consistency BUMP association resultValidation MAT]=');
fprintf(' %.6f',report.seedMedianTimes_s); fprintf('\n');

save(fullfile(root,'output','v017-verification.mat'),'report');
fprintf('V17 EXAMPLES=17 ANALYZER=%d/%d DAG=%d HIDDEN=0 READINESS_SEARCH=0\n', ...
    report.analyzerIssueCount,report.analyzerFileCount,size(edges,1));
fprintf('V17_MEDIAN_s [concept validation derivation readiness scenario delegatedExecution resultValidation MAT]=');
fprintf(' %.6f',report.medianTimes_s); fprintf('\n');
end

function restore(old,visible)
profile off; path(old); set(groot,'DefaultFigureVisible',visible);
end


