function report = verifyV13()
%VERIFYV13 Thirteen examples, Analyzer/DAG, explicit physical profiles and costs.
root=fileparts(fileparts(mfilename('fullpath'))); old=path; visible=get(groot,'DefaultFigureVisible');
cleanup=onCleanup(@() restore(old,visible));
addpath(root,fullfile(root,'src'),fullfile(root,'examples')); set(groot,'DefaultFigureVisible','off');
assert(fsd.version()=="0.13.0"); historical=verifyV08();
extra=["vehicleStaticEquilibriumExample","globalStaticEquilibriumExample", ...
    "designTargetEvaluationExample","inverseSuspensionSynthesisExample","axleSuspensionSynthesisExample"];
outputs=cell(5,1);
for i=1:5, outputs{i}=feval(extra(i),false); fprintf('EXAMPLE_OK=%s\n',extra(i)); end
edges=historical.moduleDependencies; assert(~any(edges(:,2)=="synthesis"));
oldSynthesis=outputs{4}.result; assert(oldSynthesis.statistics.physicalBumpSweeps==7);
e=outputs{5}; result=e.result; s=e.space; first=result.search.records{1}; best=result.search.records{result.selectedIndex};
assert(first.score>best.score && ~isequaln(first.axleIdentity.leftGeometryIdentity,best.axleIdentity.leftGeometryIdentity) && ...
    ~isequaln(first.axleIdentity.rightGeometryIdentity,best.axleIdentity.rightGeometryIdentity));
profile clear; profile on; physical=fsd.synthesis.runAxleInverseSearch(s,struct('maxEvaluations',1)); profile off;
info=profile('info'); names=string({info.FunctionTable.FunctionName});
bump=info.FunctionTable(endsWith(names,'solveBumpSweep')); roll=info.FunctionTable(endsWith(names,'solveAxleRollSweep'));
assert(sum([bump.NumCalls])==2 && sum([roll.NumCalls])==1 && physical.statistics.totalPhysicalSweepInvocations==3);
profile clear; profile on;
fsd.synthesis.validateAxleSynthesisResult(result);
fsd.analysis.evaluateDesignCandidate(s.specification,best.candidate);
fsd.synthesis.compareAxleSynthesisCandidates(result,[1;result.selectedIndex]);
figures=fsd.synthesis.plotAxleSynthesisResult(result,[1;result.selectedIndex]); profile off;
info=profile('info'); names=string({info.FunctionTable.FunctionName});
assert(~any(contains(names,["fsolve","fzero","solveBump","solveAxleRoll","solveCornerPath"])));
folder=fullfile(root,'output','v0.13-qa'); if ~isfolder(folder), mkdir(folder); end
for appearance=["dark","light"]
    for k=1:numel(figures)
        theme(figures(k),appearance);
        exportgraphics(figures(k),fullfile(folder,appearance+"-"+k+".png"),'Resolution',110);
    end
end
close(figures);
times=zeros(3,10); cacheSpace=axleSynthesisFixture();
cacheU=fsd.synthesis.normalizeAxleVariables(cacheSpace,cacheSpace.initial_m);
cacheOptions=struct('maxEvaluations',10,'maxIterations',4,'initialStep',1,'minimumStep',1,'seeds',cacheU');
for i=1:4
    timer=tic; fsd.synthesis.buildAxleCandidate(s,s.initial_m); t1=toc(timer);
    timer=tic; fsd.model.validateAxleGeometry(first.axle); t2=toc(timer);
    timer=tic; fsd.kinematics.solveBumpSweep(first.axle.leftGeometry,s.plan.leftBump.travel_m,'m',s.plan.leftBump.solverOptions); t3=toc(timer);
    timer=tic; fsd.kinematics.solveBumpSweep(first.axle.rightGeometry,s.plan.rightBump.travel_m,'m',s.plan.rightBump.solverOptions); t4=toc(timer);
    timer=tic; fsd.kinematics.solveAxleRollSweep(first.axle,s.plan.roll.angles_rad,0,'rad','m',s.plan.roll.solverOptions); t5=toc(timer);
    timer=tic; fsd.analysis.evaluateDesignCandidate(s.specification,first.candidate); t6=toc(timer);
    timer=tic; small=fsd.synthesis.runAxleInverseSearch(s,struct('maxEvaluations',3)); t7=toc(timer);
    timer=tic; fsd.synthesis.validateAxleSynthesisResult(result); t8=toc(timer);
    timer=tic; cache=fsd.synthesis.runAxleInverseSearch(cacheSpace,cacheOptions); t9=toc(timer);
    timer=tic; plotted=fsd.synthesis.plotAxleSynthesisResult(small,[]); t10=toc(timer); close(plotted);
    if i>1, times(i-1,:)=[t1,t2,t3,t4,t5,t6,t7,t8,t9,t10]; end
end
% Separate no-ROLL fixture measures a physical search containing cache reuse.
assert(cache.statistics.cacheHits>0);
report=struct('version',fsd.version(),'release',string(version('-release')), ...
    'exampleNames',[historical.exampleNames,extra],'exampleCount',13, ...
    'analyzerIssueCount',historical.analyzerIssueCount,'analyzerFileCount',historical.analyzerFileCount, ...
    'moduleDependencies',edges,'physicalStatistics',result.statistics,'profileBumpSweeps',sum([bump.NumCalls]), ...
    'profileRollSweeps',sum([roll.NumCalls]),'hiddenSolves',0,'seedScore',first.score,'selectedScore',best.score, ...
    'selectedIndex',result.selectedIndex,'timingSamples_s',times,'medianTimes_s',median(times,1), ...
    'smallStatistics',small.statistics,'cacheStatistics',cache.statistics, ...
    'v12Compatible',true,'pngCount',2*numel(figures));
save(fullfile(root,'output','v013-verification.mat'),'report');
fprintf('V13_EXAMPLES=13/13 ANALYZER=%d/%d; E%d BUMP_L%d BUMP_R%d ROLL%d; HIDDEN_SOLVES=0\n', ...
    report.analyzerIssueCount,report.analyzerFileCount,result.statistics.axleCandidateEvaluations, ...
    result.statistics.leftBumpSweeps,result.statistics.rightBumpSweeps,result.statistics.rollSweeps);
fprintf('V13_MEDIAN_s [builder validate left right roll evaluation search validator cacheSearchNoRoll reporting]=');
fprintf(' %.6f',report.medianTimes_s); fprintf('\n');
end

function restore(old,visible)
path(old); set(groot,'DefaultFigureVisible',visible);
end
