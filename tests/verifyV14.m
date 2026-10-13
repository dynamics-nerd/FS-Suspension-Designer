function report = verifyV14()
%VERIFYV14 Fourteen examples, Analyzer/DAG, physical counters and warmed costs.
root=fileparts(fileparts(mfilename('fullpath'))); old=path; visible=get(groot,'DefaultFigureVisible');
cleanup=onCleanup(@() restore(old,visible));
addpath(root,fullfile(root,'src'),fullfile(root,'examples')); set(groot,'DefaultFigureVisible','off');
assert(fsd.version()=="0.14.0"); historical=verifyV08();
extra=["vehicleStaticEquilibriumExample","globalStaticEquilibriumExample","designTargetEvaluationExample", ...
    "inverseSuspensionSynthesisExample","axleSuspensionSynthesisExample","steeringSynthesisExample"];
outputs=cell(numel(extra),1);
for j=1:numel(extra), outputs{j}=feval(extra(j),false); fprintf('EXAMPLE_OK=%s\n',extra(j)); end
v12=outputs{4}.result; v13=outputs{5}.result; e=outputs{6}; r=e.result; s=e.space;
assert(v12.search.evaluationCount==7 && v12.statistics.physicalBumpSweeps==7);
assert(abs(v12.search.records{1}.score-.101722096447)<1e-12 && v12.search.records{v12.selectedIndex}.score==0);
assert(v13.search.evaluationCount==7 && v13.statistics.leftBumpSweeps==7 && ...
    v13.statistics.rightBumpSweeps==7 && v13.statistics.rollSweeps==7);
assert(abs(v13.search.records{1}.score-.0860731195961)<1e-12 && v13.search.records{v13.selectedIndex}.score==0);
first=r.search.records{1}; best=r.search.records{r.selectedIndex}; assert(best.score<first.score);
fprintf('V14_PHASE=PHYSICAL_PROFILE\n');
assert(e.tradeoffValues(3,1)<e.tradeoffValues(1,1) && e.tradeoffValues(3,3)>e.tradeoffValues(1,3));
profile clear; profile on;
physical=fsd.synthesis.runSteeringInverseSearch(s,struct('maxEvaluations',1));
profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
bump=info.FunctionTable(endsWith(names,'solveBumpSweep')); rack=info.FunctionTable(endsWith(names,'solveRackSweep'));
roll=info.FunctionTable(endsWith(names,'solveAxleRollSweep'));
assert(sum([bump.NumCalls])==2 && sum([rack.NumCalls])==1 && isempty(roll));
assert(physical.statistics.totalPhysicalSweepInvocations==3);
fprintf('V14_PHASE=CONSUMER_PROFILE\n');
profile clear; profile on;
fsd.synthesis.validateSteeringSynthesisResult(r);
fsd.analysis.evaluateDesignCandidate(s.specification,best.candidate);
fsd.synthesis.compareSteeringSynthesisCandidates(r,[1;r.selectedIndex]);
% Profile trace/diagnostics separately from exporting many graphical windows.
% Full source/target/geometry plots are also profiled in the reporting tests.
profileFigures=fsd.synthesis.plotSteeringSynthesisResult(r,[]); profile off;
info=profile('info'); names=string({info.FunctionTable.FunctionName});
assert(~any(contains(names,["fsolve","fzero","solveBump","solveRack","solveAxleRoll","solveCornerPath"])));
close(profileFigures); fprintf('V14_PHASE=FULL_PLOTS_AND_PNG\n');
figures=fsd.synthesis.plotSteeringSynthesisResult(r,(1:numel(r.search.records))');
tradeoffFigures=fsd.analysis.plotDesignTargetEvaluation(e.tradeoffSpecification, ...
    cellfun(@(q) q.candidate,r.search.records,'UniformOutput',false));
for j=1:numel(tradeoffFigures)
    tradeoffFigures(j).Position=[50,50,1300,850];
    set(findall(tradeoffFigures(j),'Type','legend'),'Location','eastoutside');
end
figures=[figures;tradeoffFigures];
folder=fullfile(root,'output','v0.14-qa'); if ~isfolder(folder), mkdir(folder); end
for appearance=["dark","light"]
    for j=1:numel(figures)
        theme(figures(j),appearance);
        exportgraphics(figures(j),fullfile(folder,appearance+"-"+j+".png"),'Resolution',110);
    end
end
pngCount=2*numel(figures); close(figures); fprintf('V14_PHASE=WARMED_TIMING\n');
cacheSpace=steeringSynthesisFixture(); cacheU=fsd.synthesis.normalizeSteeringVariables(cacheSpace,cacheSpace.initial_m);
cacheOptions=struct('maxEvaluations',5,'maxIterations',2,'initialStep',1,'minimumStep',1,'seeds',cacheU');
times=zeros(3,11);
for j=1:4
    timer=tic; fsd.synthesis.buildSteeringCandidate(s,s.initial_m); t1=toc(timer);
    timer=tic; fsd.model.validateSteeringSystemGeometry(first.steering); t2=toc(timer);
    timer=tic; fsd.kinematics.solveBumpSweep(first.axle.leftGeometry,s.plan.leftBump.travel_m,'m',s.plan.leftBump.solverOptions); t3=toc(timer);
    timer=tic; fsd.kinematics.solveBumpSweep(first.axle.rightGeometry,s.plan.rightBump.travel_m,'m',s.plan.rightBump.solverOptions); t4=toc(timer);
    timer=tic; fsd.kinematics.solveRackSweep(first.steering,s.plan.rack.travel_m,s.plan.rack.wheelTravel_m,'m',s.plan.rack.solverOptions); t5=toc(timer);
    timer=tic; fsd.kinematics.solveAxleRollSweep(first.axle,[-.01;0;.01],0,'rad','m'); t6=toc(timer);
    timer=tic; fsd.analysis.evaluateDesignCandidate(s.specification,first.candidate); t7=toc(timer);
    timer=tic; fsd.synthesis.validateSteeringSynthesisResult(r); t8=toc(timer);
    timer=tic; small=fsd.synthesis.runSteeringInverseSearch(s,struct('maxEvaluations',3,'maxIterations',1)); t9=toc(timer);
    timer=tic; cache=fsd.synthesis.runSteeringInverseSearch(cacheSpace,cacheOptions); t10=toc(timer);
    timer=tic; plotted=fsd.synthesis.plotSteeringSynthesisResult(small,[]); t11=toc(timer); close(plotted);
    if j>1, times(j-1,:)=[t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11]; end
end
assert(cache.statistics.cacheHits>0);
edges=historical.moduleDependencies; assert(~any(edges(:,2)=="synthesis"));
report=struct('version',fsd.version(),'release',string(version('-release')), ...
    'exampleNames',[historical.exampleNames,extra],'exampleCount',14, ...
    'analyzerIssueCount',historical.analyzerIssueCount,'analyzerFileCount',historical.analyzerFileCount, ...
    'moduleDependencies',edges,'physicalStatistics',r.statistics,'profileBumpSweeps',sum([bump.NumCalls]), ...
    'profileRackSweeps',sum([rack.NumCalls]),'hiddenSolves',0,'seedScore',first.score,'selectedScore',best.score, ...
    'selectedIndex',r.selectedIndex,'tradeoffValues',e.tradeoffValues, ...
    'timingSamples_s',times,'medianTimes_s',median(times,1),'cacheStatistics',cache.statistics, ...
    'v12Statistics',v12.statistics,'v13Statistics',v13.statistics,'pngCount',pngCount);
save(fullfile(root,'output','v014-verification.mat'),'report');
fprintf('V14_EXAMPLES=14/14 ANALYZER=%d/%d; E%d BUMP_L%d BUMP_R%d RACK%d ROLL%d; HIDDEN_SOLVES=0\n', ...
    report.analyzerIssueCount,report.analyzerFileCount,r.search.evaluationCount, ...
    r.statistics.leftBumpSweeps,r.statistics.rightBumpSweeps,r.statistics.rackSweeps,r.statistics.rollSweeps);
fprintf('V14_MEDIAN_s [builder validate left right rack roll assessment validator search cacheSearch reporting]=');
fprintf(' %.6f',report.medianTimes_s); fprintf('\n');
end

function restore(old,visible)
path(old); set(groot,'DefaultFigureVisible',visible);
end
