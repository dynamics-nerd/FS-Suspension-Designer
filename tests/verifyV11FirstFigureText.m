function report = verifyV11FirstFigureText(appearance, visibility, scenario)
%VERIFYV11FIRSTFIGURETEXT Fresh-process F-05 regression; auto NEVER calls theme.
% Run separately via matlab -batch, before any figure, for all four cases.
arguments
    appearance (1,1) string {mustBeMember(appearance,["auto","dark","light"])} = "auto"
    visibility (1,1) string {mustBeMember(visibility,["off","on"])} = "off"
    scenario (1,1) string {mustBeMember(scenario,["PEAK","MULTI","PARTIAL","GAP"])} = "PEAK"
end
assert(isempty(findall(groot,"Type","figure")),"Use a fresh MATLAB process without any earlier figure.");
root = fileparts(fileparts(mfilename("fullpath"))); folder = fullfile(root,"output","v0.11-f05-qa");
if ~isfolder(folder), mkdir(folder); end
oldVisible = get(groot,"DefaultFigureVisible");
cleanup = onCleanup(@() set(groot,"DefaultFigureVisible",oldVisible));
set(groot,"DefaultFigureVisible",visibility);
c = designEvaluationFixture([-.01;.01],[0;0]); x = [-.01;0;.01]; v = [0;.005;0];
if scenario == "MULTI"
    b = designEvaluationFixture([-.01;-.005;0;.005;.01],zeros(5,1));
    d = b.definitionSI; d.metadata = b.metadata; d.id = "DENSE_B"; b = fsd.model.createDesignCandidate(d);
    c = {c;b};
elseif scenario == "PARTIAL"
    x = [-.02;-.01;0;.01;.02]; v = [0;.001;.005;.001;0]; c = designEvaluationFixture();
elseif scenario == "GAP"
    [~,act,~,d,u] = springDamperFixture(); d.damper.minimumLength = act.damper.staticLength_m-.003;
    model = fsd.model.createSpringDamperModel(act,d,u); x = [-.02;-.01;0;.01;.02]; v = [0;.005;0;0;0];
    r = fsd.analysis.analyzePrescribedSpringDamperPath(model,x,v,0,struct("length","m","velocity","m/s"));
    c = fsd.model.createDesignCandidate(struct("id","GAP_CANDIDATE","sources",{{ ...
        struct("id","MECH_FL","type","MECHANICAL","model",model,"result",r)}}));
end
if ~iscell(c), c = {c}; end
t = designTargetFixture("CURVE_TARGET","DAMPER_COMPRESSION",struct("x",x,"value",v,"tolerance",.001));
s = designSpecificationFixture(t);
before = cellfun(@(candidate) fsd.analysis.evaluateDesignCandidate(s,candidate),c,"UniformOutput",false);
profile clear; profile on; fig = fsd.analysis.plotDesignTargetEvaluation(s,c); profile off;
closeFirst = onCleanup(@() close(fig));
info = profile("info"); names = string({info.FunctionTable.FunctionName});
assert(~any(contains(names,["solveBump","solveSteering","solveRack","solveGlobal", ...
    "solveCorner","solveActuation","solveAxle","fsolve","fzero","lsqnonlin"])),"Plot cannot execute solvers.");
set(fig,"WindowStyle","normal","WindowState","normal","Position",[100,100,1100,700]);
if appearance ~= "auto", theme(fig,appearance); end
stem = appearance+"-"+visibility;
if scenario ~= "PEAK", stem = stem+"-"+scenario; end
report = designTargetRenderCheck(fig,fullfile(folder,"first-"+stem+".png"));
report.exterior = designExteriorTextCheck(fig,report.pngPath);
after = cellfun(@(candidate) fsd.analysis.evaluateDesignCandidate(s,candidate),c,"UniformOutput",false);
assert(isequaln(before,after),"Rendering cannot change evaluation.");
if scenario == "PEAK" || scenario == "MULTI"
    assert(before{1}.targetAssessments{1}.status == "SAMPLED_PASS");
else
    assert(before{1}.targetAssessments{1}.domainCoverage == .5);
end
target = findobj(fig,"Type","line","DisplayName","Target");
assert(isequal(target.XData(:),x) && isequal(target.YData(:),v),"Original target knots required.");
for name = ["Lower acceptance","Upper acceptance"]
    line = findobj(fig,"Type","line","DisplayName",name);
    sign = -1; if name == "Upper acceptance", sign = 1; end
    assert(max(abs(line.YData(:)-(v+sign*.001))) < 1e-15,"Original bands must be preserved.");
end
actual = findobj(target.Parent,"Type","line","Marker","o");
if scenario == "GAP", assert(any(isnan(actual.YData)),"Native internal gap required."); end
% Let the visible frontend finish mounting AFTER the immediate first export.
% Waiting before the first export could conceal the original auto-theme defect.
if visibility == "on", drawnow; pause(1); end
set(fig,"Position",[100,100,900,600]);
% QA-only wait for visible-window resize, NOT a theme/contrast solution.
if visibility == "on", drawnow; pause(1); end
report.resized = designTargetRenderCheck(fig,fullfile(folder,"resized-"+stem+".png"));
report.resized.exterior = designExteriorTextCheck(fig,report.resized.pngPath);
originalPixels = imread(report.pngPath); resizedPixels = imread(report.resized.pngPath);
assert(~isequal(size(originalPixels),size(resizedPixels)),"Resize must change actual PNG dimensions.");
second = fsd.analysis.plotDesignTargetEvaluation(s,c); closeSecond = onCleanup(@() close(second));
if appearance ~= "auto", theme(second,appearance); end
set(second,"Position",[100,100,1100,700]);
report.second = designTargetRenderCheck(second,fullfile(folder,"second-"+stem+".png"));
report.second.exterior = designExteriorTextCheck(second,report.second.pngPath);
assert(get(groot,"DefaultFigureVisible") == visibility,"No global visibility mutation by plot.");
report.solverCalls = 0; report.scenario = scenario;
save(fullfile(folder,"first-"+stem+".mat"),"report");
fprintf("FIRST_TEXT=%s/%s; THEME=%s; MIN_TEXT_PNG_CONTRAST=%.6f; TARGET=%.6f; WARNINGS=0; SOLVES=0\n", ...
    appearance,visibility,report.theme,min(report.exterior.textContrast),report.pngContrast);
disp(report.exterior);
end
