function report = verifyV12Audit(mode)
%VERIFYV12AUDIT Fresh-session PNGs or examples/DAG/Analyzer/profiles/performance.
if nargin<1, mode="ALL"; end
root=fileparts(fileparts(mfilename('fullpath'))); original=path; visible=get(groot,'DefaultFigureVisible');
cleanup=onCleanup(@() restore(original,visible)); addpath(root,fullfile(root,'src'),fullfile(root,'examples'));
set(groot,'DefaultFigureVisible','off');
folder=fullfile(root,'output','v0.12-audit-qa',mode);
if startsWith(mode,"FIRST_")
    assert(isempty(findall(groot,'Type','figure')),'Fresh-session check must precede every figure.');
    if mode=="FIRST_SINGLE", s=synthesisFixture(); else, s=synthesisFailureFixture(); end
    r=fsd.synthesis.runInverseSearch(s,struct('maxEvaluations',1));
    report=synthesisPlotAuditCheck(r,folder,"dark");
    fprintf('FRESH_SESSION_PNG_OK=%s\n',mode); return;
end
assert(mode=="ALL"); historical=verifyV12(); [s,o]=synthesisFixture();
failureSpace=synthesisFailureFixture(); r=fsd.synthesis.runInverseSearch(s,o);
one=fsd.synthesis.runInverseSearch(s,struct('maxEvaluations',1));
u=fsd.synthesis.normalizeVariables(failureSpace,failureSpace.initial_m); times=zeros(3,7);
for i=1:4
    timer=tic; fsd.synthesis.validateSynthesisEvaluation(r.search.records{1},s); a=toc(timer);
    timer=tic; fsd.synthesis.validateSynthesisResult(r); b=toc(timer);
    timer=tic; fsd.synthesis.evaluateSynthesisCandidate(failureSpace,u); c=toc(timer);
    timer=tic; fsd.synthesis.runInverseSearch(s,o); d=toc(timer);
    timer=tic; fsd.synthesis.runInverseSearch(failureSpace,struct('maxEvaluations',5)); e=toc(timer);
    timer=tic; f=fsd.synthesis.plotSynthesisResult(one); g=toc(timer); close(f);
    timer=tic; f=fsd.synthesis.plotSynthesisResult(r,[1;r.selectedIndex]); h=toc(timer); close(f);
    if i>1, times(i-1,:)=[a,b,c,d,e,g,h]; end
end
profile clear; profile on;
failed=fsd.synthesis.runInverseSearch(failureSpace,struct('maxEvaluations',5)); profile off;
info=profile('info'); names=string({info.FunctionTable.FunctionName});
calls=info.FunctionTable(contains(names,'solveBumpSweep')); count=sum([calls.NumCalls]);
assert(count==5 && failed.statistics.physicalBumpSweeps==5);
profile clear; profile on;
fsd.synthesis.validateSynthesisResult(r); fsd.synthesis.validateSynthesisResult(failed); profile off;
info=profile('info'); names=string({info.FunctionTable.FunctionName});
assert(~any(contains(names,["solveBump","fsolve","fzero"])));
assert(r.search.evaluationCount==7 && r.statistics.physicalBumpSweeps==7 && ...
    r.search.stopReason=="SCORE_TARGET_REACHED" && r.search.records{r.selectedIndex}.score==0);
assert(abs(r.search.records{1}.score-.101722096447)<1e-12); % historical benchmark precision
report=struct('historical',historical,'medianTimes_s',median(times,1),'measurements_s',times, ...
    'failedSearch',failed,'normalSearch',r,'failedPhysicalSweepCount',count,'validatorSolves',0);
save(fullfile(root,'output','v012-audit-verification.mat'),'report');
fprintf('AUDIT_MEDIAN_s [evalValidation resultValidation failure normalSearch failedSearch onePlot multiPlot]=');
fprintf(' %.6f',report.medianTimes_s); fprintf('\nAUDIT_FAILED_SWEEPS=%d; VALIDATOR_SOLVES=0\n',count);
end
function restore(original,visible)
path(original); set(groot,'DefaultFigureVisible',visible);
end
