function report = verifyV12()
%VERIFYV12 Twelve real examples, Analyzer/DAG, fresh physical costs and native PNGs.
root=fileparts(fileparts(mfilename('fullpath'))); old=path; visible=get(groot,'DefaultFigureVisible');
cleanup=onCleanup(@() restore(old,visible));
addpath(root,fullfile(root,'src'),fullfile(root,'examples')); set(groot,'DefaultFigureVisible','off');
assert(fsd.version()=="0.12.0");
historical=verifyV08(); % preserved verifier without version lock: eight examples + all .m/DAG
extra=["vehicleStaticEquilibriumExample","globalStaticEquilibriumExample", ...
    "designTargetEvaluationExample","inverseSuspensionSynthesisExample"];
outputs=cell(4,1);
for i=1:4, outputs{i}=feval(extra(i),false); fprintf('EXAMPLE_OK=%s\n',extra(i)); end
edges=historical.moduleDependencies;
assert(~any(edges(:,2)=="synthesis"),'Existing modules cannot depend on synthesis.');
e=outputs{4}; space=e.space; u=fsd.synthesis.normalizeVariables(space,space.initial_m);
record=e.result.search.records{1}; g=record.geometry; source=record.candidate.definitionSI.sources{1};
[invalidSpace,invalidU]=degenerateFixture(space);
times=zeros(3,9); stats=cell(3,1);
for i=1:4
    timer=tic; fsd.synthesis.buildCandidateGeometry(space,space.initial_m); t1=toc(timer);
    timer=tic; fsd.model.validateDoubleWishboneGeometry(g); t2=toc(timer);
    timer=tic; fsd.kinematics.solveBumpSweep(g,space.plan.travel_m,'m',space.plan.solverOptions); t3=toc(timer);
    timer=tic; fsd.analysis.evaluateDesignCandidate(space.specification,record.candidate); t4=toc(timer);
    timer=tic; fsd.synthesis.runInverseSearch(space,struct('maxIterations',1)); t5=toc(timer);
    timer=tic; full=fsd.synthesis.runInverseSearch(space,e.result.search.options); t6=toc(timer);
    timer=tic; fsd.synthesis.evaluateSynthesisCandidate(space,u); t7=toc(timer);
    timer=tic; fsd.synthesis.evaluateSynthesisCandidate(invalidSpace,invalidU); t8=toc(timer);
    timer=tic; fsd.analysis.analyzeBumpSweep(g,source.sweep); t9=toc(timer);
    if i>1, times(i-1,:)=[t1,t2,t3,t4,t5,t6,t7,t8,t9]; stats{i-1}=full.statistics; end
end
profile clear; profile on; physical=fsd.synthesis.runInverseSearch(space,e.result.search.options); profile off;
info=profile('info'); names=string({info.FunctionTable.FunctionName}); calls=info.FunctionTable(contains(names,'solveBumpSweep'));
assert(sum([calls.NumCalls])==physical.statistics.physicalBumpSweeps);
profile clear; profile on; fsd.analysis.evaluateDesignCandidate(space.specification,record.candidate); profile off;
info=profile('info'); names=string({info.FunctionTable.FunctionName});
assert(~any(contains(names,["solveBump","fsolve","fzero"])));
figures=fsd.synthesis.plotSynthesisResult(e.result,[1;e.result.selectedIndex]);
folder=fullfile(root,'output','v0.12-qa'); if ~isfolder(folder), mkdir(folder); end
for appearance=["dark","light"]
    for i=1:numel(figures)
        theme(figures(i),appearance); set(figures(i),'Position',[50,50,1100,900]);
        exportgraphics(figures(i),fullfile(folder,appearance+"-"+i+".png"),'Resolution',120);
    end
end
close(figures);
prefixLabelCheck(space);
report=struct('release',string(version('-release')),'version',fsd.version(), ...
    'baselineExpected',719,'exampleNames',[historical.exampleNames,extra],'exampleCount',12, ...
    'analyzerFileCount',historical.analyzerFileCount,'analyzerIssueCount',historical.analyzerIssueCount, ...
    'moduleDependencies',edges,'sampleCount',numel(space.plan.travel_m),'medianTimes_s',median(times,1), ...
    'fullSearchStatistics',{stats},'realPhysicalSweepCount',physical.statistics.physicalBumpSweeps, ...
    'evaluationHiddenSolves',0,'seedScore',e.result.search.records{1}.score, ...
    'selectedScore',e.result.search.records{e.result.selectedIndex}.score,'prefixLabelCheck',true);
save(fullfile(root,'output','v012-verification.mat'),'report');
fprintf('V12_EXAMPLES=12/12; ANALYZER=%d/%d; PHYSICAL_SWEEPS=%d; EVALUATOR_SOLVES=0\n', ...
    report.analyzerIssueCount,report.analyzerFileCount,report.realPhysicalSweepCount);
fprintf('V12_MEDIAN_s [build validate sweep v11eval iteration full valid invalid analysis]='); fprintf(' %.6f',report.medianTimes_s); fprintf('\n');
end

function prefixLabelCheck(space)
% IDs SYNTH_1 and SYNTH_10 must not be confused by display-name prefix matching.
r=fsd.synthesis.runInverseSearch(space,struct('maxEvaluations',12,'maxIterations',20,'stopAtScore',[]));
assert(r.search.evaluationCount>=10);
figures=fsd.synthesis.plotSynthesisResult(r,[1;10]); cleanup=onCleanup(@() close(figures));
lines=findall(figures,'Type','line'); names=string({lines.DisplayName});
selected=startsWith(names,"SYNTH_10 ");
assert(any(selected) && all(count(names(selected),"| synthesis")==1),'Candidate labels must use exact IDs, not overlapping prefixes.');
end

function [space,u] = degenerateFixture(original)
seed=original.seed; seed.hardpoints.xyz_m(1,2:3)=seed.hardpoints.xyz_m(2,2:3);
nominal=seed.hardpoints.xyz_m(1,1);
p=struct('id',"DEGENERATE_X",'quantity',"LENGTH",'scope',fsd.model.designScope('HARDPOINT',seed.hardpoints.ids(1),'FL'), ...
    'type',"FREE",'binding',"HARDPOINT_X",'value',nominal,'bounds',[nominal,seed.hardpoints.xyz_m(2,1)], ...
    'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Invalid geometry cost fixture, not a design");
d=original.specification.definitionSI; d.parameters={fsd.model.createDesignParameter(p,'m')};
space=fsd.synthesis.createDesignSpace(seed,fsd.model.createDesignSpecification(d),original.plan); u=1;
end
function restore(old,visible)
path(old); set(groot,'DefaultFigureVisible',visible);
end
