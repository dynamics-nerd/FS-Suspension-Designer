function report = verifyV19()
%VERIFYV19 Explicit R2026b example/benchmark/Analyzer/DAG verification.
% Run in an isolated repository copy: historical examples write fixed MAT paths.
root=fileparts(fileparts(mfilename('fullpath'))); old=path;
cleanup=onCleanup(@()path(old)); addpath(root,fullfile(root,'src'),fullfile(root,'examples'),fullfile(root,'app'));
assert(fsd.version()=="0.19.0");
exampleNames=["staticDoubleWishboneExample","bumpKinematicsExample","singleCornerAnalysisExample", ...
    "axleRollCenterExample","steeringKinematicsExample","bodyRollKinematicsExample", ...
    "actuationKinematicsExample","springDamperWheelRateExample","vehicleStaticEquilibriumExample", ...
    "globalStaticEquilibriumExample","designTargetEvaluationExample","inverseSuspensionSynthesisExample", ...
    "axleSuspensionSynthesisExample","steeringSynthesisExample","actuationSynthesisExample", ...
    "vehicleConceptProjectExample","conceptToSeedExample","packagingFeasibilityExample"];
outputs=cell(numel(exampleNames),1); exampleTimes_s=zeros(numel(exampleNames),1);
for j=1:numel(exampleNames)
    started=tic; outputs{j}=feval(exampleNames(j),false); exampleTimes_s(j)=toc(started);
    fprintf('EXAMPLE_OK=%s SECONDS=%.6f\n',exampleNames(j),exampleTimes_s(j));
end
v12=outputs{12}.result; v13=outputs{13}.result; v14=outputs{14}.result;
v15=outputs{15}.result; v16=outputs{16}.result.nativePayload; v17=outputs{17}.search.nativePayload;
assert(v12.search.evaluationCount==7 && v12.statistics.physicalBumpSweeps==7);
assert(v13.search.evaluationCount==7 && v13.statistics.leftBumpSweeps==7 && v13.statistics.rightBumpSweeps==7 && v13.statistics.rollSweeps==7);
assert(v14.search.evaluationCount==3 && v14.statistics.leftBumpSweeps==3 && ...
    v14.statistics.rightBumpSweeps==3 && v14.statistics.rackSweeps==3);
assert(v15.search.evaluationCount==8 && v15.statistics.bumpSweeps==8 && v15.statistics.actuationSweeps==8 && v15.statistics.mechanicalAnalyses==8);
legacy=steeringSynthesisFixture(); d=legacy.specification.definitionSI; targets=d.targets.definitionSI.targets;
targets=targets(cellfun(@(q)q.definitionSI.sourceType=="RACK",targets));
for j=1:numel(targets), q=targets{j}.definitionSI; q.tolerance=0; targets{j}=fsd.model.createDesignTarget(q,'rad','m'); end
d.targets=fsd.model.createSuspensionDesignTargets(targets);
space=rebuildSteeringSpace(legacy,d);
rack=fsd.synthesis.runSteeringInverseSearch(space,struct('maxEvaluations',3,'maxIterations',1,'initialStep',.25,'minimumStep',.25));
benchmarks={v12;v13;v14;rack;v15;v16;v17};
expectedInitial=[.101722096447;.0860731195961;.441327900783;.0265716889609;.231415023063;.231415023063;.101722096447];
expectedFinal=[0;0;0;.0238159165073;0;0;0]; scores=zeros(7,2);
for j=1:7
    r=benchmarks{j}; scores(j,:)=[r.search.records{1}.score,r.search.records{r.selectedIndex}.score];
end
assert(all(abs(scores(:,1)-expectedInitial)<1e-12) && all(abs(scores(:,2)-expectedFinal)<1e-12));
assert(rack.search.evaluationCount==3 && rack.statistics.leftBumpSweeps==3 && ...
    rack.statistics.rightBumpSweeps==3 && rack.statistics.rackSweeps==3 && ...
    abs(scores(4,1)-expectedInitial(4))<1e-13 && abs(scores(4,2)-expectedFinal(4))<1e-13);
files=[dir(fullfile(root,'src','**','*.m'));dir(fullfile(root,'app','**','*.m')); ...
    dir(fullfile(root,'tests','**','*.m'));dir(fullfile(root,'examples','**','*.m'));dir(fullfile(root,'*.m'))];
analyzerCount=0;
for j=1:numel(files)
    messages=checkcode(fullfile(files(j).folder,files(j).name),'-id'); analyzerCount=analyzerCount+numel(messages);
    for message=messages', fprintf('ANALYZER %s:%d %s\n',files(j).name,message.line,message.message); end
end
assert(analyzerCount==0);
edges=strings(0,2); sourceFiles=dir(fullfile(root,'src','**','*.m'));
for j=1:numel(sourceFiles)
    file=fullfile(sourceFiles(j).folder,sourceFiles(j).name);
    token=regexp(file,'[\\/]\+fsd[\\/]\+(\w+)','tokens','once');
    code=regexprep(fileread(file),'(?m)^[ \t]*%[^\r\n]*','');
    assert(~contains(code,'fsdui.'),'Engineering core must not depend on UI.');
    if isempty(token), continue; end
    calls=regexp(code,'\<fsd\.([A-Za-z]+)\.[A-Za-z]\w*\s*\(','tokens');
    targets=unique(string([calls{:}]));
    edges=[edges;[repmat(string(token{1}),numel(targets),1),targets(:)]]; %#ok<AGROW>
end
edges=unique(edges,'rows'); edges=edges(edges(:,1)~=edges(:,2),:);
assert(isdag(digraph(edges(:,1),edges(:,2))));
assert(~any((edges(:,1)=="kinematics" & edges(:,2)=="rules") | (edges(:,1)=="rules" & edges(:,2)=="kinematics")));
assert(~any(edges(:,1)=="export" & edges(:,2)=="kinematics"));
report=struct('version',fsd.version(),'release',string(version('-release')),'exampleNames',exampleNames, ...
    'exampleTimes_s',exampleTimes_s,'exampleCount',18,'scores',scores,'analyzerCount',analyzerCount, ...
    'analyzerFiles',numel(files),'moduleDependencies',edges);
fprintf('V19_VERIFY_PASS EXAMPLES=18 ANALYZER=%d/%d EDGES=%d\n',analyzerCount,numel(files),size(edges,1));
end


