function report = verifyV08()
%VERIFYV08 Reproducible examples, Code Analyzer and warmed pipeline timing.
% Run setupProject; runProjectTests first. This does not commit or write files.
root = fileparts(fileparts(mfilename("fullpath")));
oldPath = path; cleanup = onCleanup(@() path(oldPath));
addpath(root,fullfile(root,"src"),fullfile(root,"examples"));
examples = ["staticDoubleWishboneExample","bumpKinematicsExample", ...
    "singleCornerAnalysisExample","axleRollCenterExample","steeringKinematicsExample", ...
    "bodyRollKinematicsExample","actuationKinematicsExample","springDamperWheelRateExample"];
outputs = cell(numel(examples),1);
for i = 1:numel(examples)
    outputs{i} = feval(examples(i),false);
    fprintf("EXAMPLE_OK=%s\n",examples(i));
end
files = dir(fullfile(root,"**","*.m")); issueCount = 0;
for i = 1:numel(files)
    file = fullfile(files(i).folder,files(i).name);
    issues = checkcode(file,"-id");
    issueCount = issueCount+numel(issues);
    if ~isempty(issues), fprintf("%s\n",file); disp(issues); end
end
fprintf("CODE_ANALYZER=%d issues/%d files\n",issueCount,numel(files));
assert(issueCount == 0,"Code Analyzer must have zero issues.");
edges = moduleDependencies(root);
fprintf("MODULE_DEPENDENCIES (acyclic qualified-call graph):\n"); disp(edges);
e = outputs{end}; target = (-20:2:20)'; times = zeros(3,4); cores = zeros(3,2);
for iteration = 1:4
    timer = tic;
    bump = fsd.kinematics.solveBumpSweep(e.geometry,target,"mm");
    t1 = toc(timer); timer = tic;
    act = fsd.kinematics.solveActuationSweep(e.actuation,bump);
    t2 = toc(timer); timer = tic;
    geometric = fsd.analysis.analyzeActuationSweep(e.actuation,act);
    t3 = toc(timer); timer = tic;
    mechanical = fsd.analysis.analyzeSpringDamperSweep(e.model,e.actuation,act,geometric,0.1,"m/s");
    t4 = toc(timer);
    if iteration > 1
        times(iteration-1,:) = [t1,t2,t3,t4];
        cores(iteration-1,:) = [geometric.elapsedTime_s,mechanical.elapsedTime_s];
    end
end
% Profiling is separate from timed samples, to avoid timing instrumentation.
profile clear; profile on;
fsd.analysis.analyzeSpringDamperSweep(e.model,e.actuation,act,geometric,0.1,"m/s");
profile off; info = profile("info");
names = string({info.FunctionTable.FunctionName});
assert(~any(contains(names,["fsolve","fzero","solveBump","solveActuation"])), ...
    "Mechanical evaluation must not execute kinematic/nonlinear solves.");
report = struct("matlabRelease",string(version("-release")),"exampleNames",examples, ...
    "analyzerFileCount",numel(files),"analyzerIssueCount",issueCount, ...
    "sampleCount",numel(target),"medianWallTime_s",median(times,1), ...
    "medianAnalysisCoreTime_s",median(cores,1),"mechanicalNonlinearSolveCount",0, ...
    "moduleDependencies",edges);
fprintf("PERFORMANCE_WALL_s [suspension actuation actuationAnalysis mechanicalAnalysis]=%.6f %.6f %.6f %.6f\n", ...
    report.medianWallTime_s);
fprintf("PERFORMANCE_CORE_s [actuationAnalysis mechanicalAnalysis]=%.6f %.6f\n",report.medianAnalysisCoreTime_s);
fprintf("MECHANICAL_NONLINEAR_SOLVES=0\n");
end

function edges = moduleDependencies(root)
% Qualified-call audit; full comment lines excluded, no dependency inference.
files = dir(fullfile(root,"src","**","*.m")); byFile = cell(numel(files),1);
for i = 1:numel(files)
    file = fullfile(files(i).folder,files(i).name);
    token = regexp(file,'[\\/]\+fsd[\\/]\+(\w+)','tokens','once');
    byFile{i} = strings(0,2);
    if isempty(token), continue; end
    code = regexprep(fileread(file),'(?m)^[ \t]*%[^\r\n]*','');
    matches = regexp(code,'\<fsd\.([A-Za-z]+)\.[A-Za-z]\w*\s*\(','tokens');
    targets = unique(string([matches{:}]));
    byFile{i} = [repmat(string(token{1}),numel(targets),1),targets(:)];
end
edges = unique(vertcat(byFile{:}),"rows");
edges = edges(edges(:,1) ~= edges(:,2),:);
assert(~isempty(edges),"Dependency audit must discover existing module calls.");
graph = digraph(edges(:,1),edges(:,2));
assert(isdag(graph),"Core module dependencies must be acyclic.");
assert(~any(edges(:,2) == "app"),"Core must not depend on app.");
assert(~any((edges(:,1) == "kinematics" & edges(:,2) == "rules") | ...
    (edges(:,1) == "rules" & edges(:,2) == "kinematics")),"Rules/kinematics boundary violated.");
assert(~any(edges(:,1) == "export" & edges(:,2) == "kinematics"),"Exporter must not solve kinematics.");
end
