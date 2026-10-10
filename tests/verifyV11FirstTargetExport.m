function report = verifyV11FirstTargetExport(appearance)
%VERIFYV11FIRSTTARGETEXPORT Run in a NEW matlab -batch process, before any figure.
% setupProject; addpath('tests'); verifyV11FirstTargetExport('auto'/'dark'/'light').
% 'auto' verifies the actual dark desktop environment without changing preferences.
arguments
    appearance (1,1) string {mustBeMember(appearance,["auto","dark","light"])} = "auto"
end
assert(isempty(findall(groot,"Type","figure")),"Run before creating ANY figure, in a fresh process.");
root = fileparts(fileparts(mfilename("fullpath")));
folder = fullfile(root,"output","v0.11-f04-qa"); if ~isfolder(folder), mkdir(folder); end
old = get(groot,"DefaultFigureVisible"); cleanup = onCleanup(@() set(groot,"DefaultFigureVisible",old));
set(groot,"DefaultFigureVisible","off");
c = designEvaluationFixture([-.01;.01],[0;0]); x = [-.01;0;.01]; v = [0;.005;0];
t = designTargetFixture("CURVE_TARGET","DAMPER_COMPRESSION",struct("x",x,"value",v,"tolerance",.001));
s = designSpecificationFixture(t); before = fsd.analysis.evaluateDesignCandidate(s,c);
profile clear; profile on; fig = fsd.analysis.plotDesignTargetEvaluation(s,c); profile off;
closeFirst = onCleanup(@() close(fig));
info = profile("info"); names = string({info.FunctionTable.FunctionName});
assert(~any(contains(names,["solveBump","solveSteering","solveRack","solveGlobal", ...
    "solveCorner","solveActuation","fsolve","fzero","lsqnonlin"])),"Plot must not execute engineering solvers.");
set(fig,"Position",[100,100,1100,700]);
if appearance ~= "auto", theme(fig,appearance); end % Figure-local supported R2025b API.
report = designTargetRenderCheck(fig,fullfile(folder,"first-"+appearance+".png"));
expected = appearance; if expected == "auto", expected = "dark"; end
assert(report.theme == expected,"Effective export theme must match requested environment.");
line = findobj(fig,"Type","line","DisplayName","Target");
assert(isequal(line.XData(:),x) && isequal(line.YData(:),v),"Original peak knots must survive.");
for name = ["Lower acceptance","Upper acceptance"]
    line = findobj(fig,"Type","line","DisplayName",name);
    sign = -1; if name == "Upper acceptance", sign = 1; end
    assert(max(abs(line.YData(:)-(v+sign*.001))) < 1e-15,"Bands must survive.");
end
assert(isequaln(before,fsd.analysis.evaluateDesignCandidate(s,c)),"Plot/export cannot change evaluation.");
assert(before.targetAssessments{1}.status == "SAMPLED_PASS");
second = fsd.analysis.plotDesignTargetEvaluation(s,c); closeSecond = onCleanup(@() close(second));
theme(second,expected); set(second,"Position",[100,100,1100,700]);
report.second = designTargetRenderCheck(second,fullfile(folder,"second-"+appearance+".png"));
report.solverCalls = 0; report.targetX_m = x; report.targetY_m = v;
save(fullfile(folder,"first-"+appearance+".mat"),"report");
fprintf("FIRST_EXPORT=%s; EFFECTIVE_THEME=%s; CONTRAST=%.6f; PNG_CONTRAST=%.6f; BAND=%.6f; WARNINGS=0\n", ...
    appearance,report.theme,report.targetContrast,report.pngContrast,min(report.bandContrast));
disp("BEFORE [target; axis; background]"); disp(report.beforeRGB);
disp("AFTER [target; axis; background]"); disp(report.afterRGB);
end
