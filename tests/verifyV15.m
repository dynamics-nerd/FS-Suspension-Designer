function report = verifyV15()
%VERIFYV15 Fifteen examples, native regressions, profiling and measured costs.
root=fileparts(fileparts(mfilename('fullpath'))); old=path; visible=get(groot,'DefaultFigureVisible');
cleanup=onCleanup(@()restore(old,visible));
addpath(root,fullfile(root,'src'),fullfile(root,'examples')); set(groot,'DefaultFigureVisible','off');
assert(fsd.version()=="0.15.0"); historical=verifyV08();
extra=["vehicleStaticEquilibriumExample","globalStaticEquilibriumExample","designTargetEvaluationExample", ...
    "inverseSuspensionSynthesisExample","axleSuspensionSynthesisExample","steeringSynthesisExample","actuationSynthesisExample"];
outputs=cell(numel(extra),1);
for j=1:numel(extra), outputs{j}=feval(extra(j),false); fprintf('EXAMPLE_OK=%s\n',extra(j)); end
v12=outputs{4}.result; v13=outputs{5}.result; v14=outputs{6}.result; example=outputs{7}; r=example.result; s=example.space;
assert(v12.search.evaluationCount==7 && v12.statistics.physicalBumpSweeps==7);
assert(abs(v12.search.records{1}.score-.101722096447)<1e-12 && v12.search.records{v12.selectedIndex}.score==0);
assert(v13.search.evaluationCount==7 && v13.statistics.leftBumpSweeps==7 && ...
    v13.statistics.rightBumpSweeps==7 && v13.statistics.rollSweeps==7);
assert(abs(v13.search.records{1}.score-.0860731195961)<1e-12 && v13.search.records{v13.selectedIndex}.score==0);
assert(v14.search.evaluationCount==3 && v14.statistics.leftBumpSweeps==3 && ...
    v14.statistics.rightBumpSweeps==3 && v14.statistics.rackSweeps==3);
assert(abs(v14.search.records{1}.score-.441327900783)<1e-12 && v14.search.records{v14.selectedIndex}.score==0);
legacy=steeringSynthesisFixture(); d=legacy.specification.definitionSI; targets=d.targets.definitionSI.targets;
targets=targets(cellfun(@(q)q.definitionSI.sourceType=="RACK",targets));
for j=1:numel(targets)
    q=targets{j}.definitionSI; q.tolerance=0; targets{j}=fsd.model.createDesignTarget(q,'rad','m');
end
d.targets=fsd.model.createSuspensionDesignTargets(targets);
rackOnly=fsd.synthesis.runSteeringInverseSearch(rebuildSteeringSpace(legacy,d), ...
    struct('maxEvaluations',3,'maxIterations',1,'initialStep',.25,'minimumStep',.25));
rackScores=cellfun(@(e)e.score,rackOnly.search.records);
assert(rackOnly.statistics.leftBumpSweeps==3 && rackOnly.statistics.rightBumpSweeps==3 && rackOnly.statistics.rackSweeps==3);
assert(abs(rackScores(1)-.0265716889609)<1e-13 && abs(rackScores(3)-.0238159165073)<1e-13);
first=r.search.records{1}; best=r.search.records{r.selectedIndex}; assert(best.score<first.score);
assert(isequaln(best.geometry,s.seed) && ~isequaln(best.actuationIdentity,s.seedActuation.identity));
fprintf('V15_PHASE=PHYSICAL_PROFILE\n'); profile clear; profile on;
physical=fsd.synthesis.runActuationInverseSearch(s,struct('maxEvaluations',1));
profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
bump=info.FunctionTable(endsWith(names,'solveBumpSweep')); act=info.FunctionTable(endsWith(names,'solveActuationSweep'));
assert(sum([bump.NumCalls])==1 && sum([act.NumCalls])==1 && physical.statistics.physicalSweepInvocations==2);
assert(physical.statistics.nativeRockerClosures==numel(s.plan.travel_m));
fprintf('V15_PHASE=CONSUMER_PROFILE\n'); profile clear; profile on;
fsd.synthesis.validateActuationSynthesisResult(r);
fsd.analysis.evaluateDesignCandidate(s.specification,best.candidate);
fsd.synthesis.compareActuationSynthesisCandidates(r,[1;r.selectedIndex]);
profileFigures=fsd.synthesis.plotActuationSynthesisResult(r,[]); profile off;
info=profile('info'); names=string({info.FunctionTable.FunctionName});
assert(~any(contains(names,["fsolve","fzero","solveBump","solveActuationSweep","solveActuationCore"])));
close(profileFigures);
fprintf('V15_PHASE=FULL_PLOTS_AND_PNG\n'); figures=fsd.synthesis.plotActuationSynthesisResult(r);
folder=fullfile(root,'output','v0.15-qa'); if ~isfolder(folder), mkdir(folder); end
for appearance=["dark","light"]
    for j=1:numel(figures)
        theme(figures(j),appearance); axesList=findall(figures(j),'Type','axes');
        for k=1:numel(axesList), axesList(k).Toolbar.Visible='off'; end
        exportgraphics(figures(j),fullfile(folder,appearance+"-"+j+".png"),'Resolution',110,'Padding','figure');
    end
end
pngCount=2*numel(figures); close(figures);
fprintf('V15_PHASE=WARMED_TIMING\n'); cacheSpace=actuationSynthesisFixture();
cacheU=fsd.synthesis.normalizeActuationVariables(cacheSpace,cacheSpace.initial_m);
cacheOptions=struct('maxEvaluations',8,'maxIterations',2,'initialStep',1,'minimumStep',1,'seeds',cacheU');
times=zeros(3,10); file=fullfile(root,'output','v015-timing-roundtrip.mat');
for j=1:4
    timer=tic; fsd.synthesis.buildActuationCandidate(s,s.initial_m); t1=toc(timer);
    timer=tic; fsd.model.validateActuationGeometry(first.actuation); t2=toc(timer);
    timer=tic; native=fsd.kinematics.solveActuationSweep(first.actuation,first.bumpEvidence.sweep); t3=toc(timer);
    geometry=fsd.analysis.analyzeActuationSweep(first.actuation,native);
    timer=tic; fsd.analysis.analyzeSpringDamperSweep(first.mechanical,first.actuation,native,geometry, ...
        s.plan.wheelVelocity_m_per_s,'m/s'); t4=toc(timer);
    timer=tic; fsd.analysis.evaluateDesignCandidate(s.specification,first.candidate); t5=toc(timer);
    timer=tic; small=fsd.synthesis.runActuationInverseSearch(s,struct('maxEvaluations',3,'maxIterations',1)); t6=toc(timer);
    timer=tic; cache=fsd.synthesis.runActuationInverseSearch(cacheSpace,cacheOptions); t7=toc(timer);
    timer=tic; fsd.synthesis.validateActuationSynthesisResult(r); t8=toc(timer);
    timer=tic; save(file,'r'); loaded=load(file,'r'); t9=toc(timer); assert(isequaln(loaded.r,r));
    timer=tic; plotted=fsd.synthesis.plotActuationSynthesisResult(small,[]); t10=toc(timer); close(plotted);
    if j>1, times(j-1,:)=[t1,t2,t3,t4,t5,t6,t7,t8,t9,t10]; end
end
assert(cache.statistics.cacheHits>0); edges=historical.moduleDependencies; assert(~any(edges(:,2)=="synthesis"));
% Cache cost here is the whole cached search, not an isolated lookup latency.
report=struct('version',fsd.version(),'release',string(version('-release')), ...
    'exampleNames',[historical.exampleNames,extra],'exampleCount',15, ...
    'analyzerIssueCount',historical.analyzerIssueCount,'analyzerFileCount',historical.analyzerFileCount, ...
    'moduleDependencies',edges,'physicalStatistics',r.statistics,'profileBumpSweeps',sum([bump.NumCalls]), ...
    'profileActuationSweeps',sum([act.NumCalls]),'hiddenSolves',0,'seedScore',first.score, ...
    'selectedScore',best.score,'selectedIndex',r.selectedIndex,'timingSamples_s',times, ...
    'medianTimes_s',median(times,1),'cacheStatistics',cache.statistics, ...
    'v12',v12,'v13',v13,'v14',v14,'rackOnly',rackOnly,'rackOnlyScores',rackScores,'actuationExample',example,'pngCount',pngCount);
save(fullfile(root,'output','v015-verification.mat'),'report');
fprintf('V15 EXAMPLES=15 ANALYZER=%d/%d E%d BUMP%d ACT%d MECH%d HIDDEN=0 score %.12g -> %.12g\n', ...
    report.analyzerIssueCount,report.analyzerFileCount,r.search.evaluationCount,r.statistics.bumpSweeps, ...
    r.statistics.actuationSweeps,r.statistics.mechanicalAnalyses,first.score,best.score);
fprintf('V15_MEDIAN_s [builder validate actuation mechanical assessment search cachedSearch resultValidator MAT traceReporting]=');
fprintf(' %.6f',report.medianTimes_s); fprintf('\n');
end

function restore(old,visible)
path(old); set(groot,'DefaultFigureVisible',visible);
end
