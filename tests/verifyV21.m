function report=verifyV21()
%VERIFYV21 Static checks and test inventory, not a full regression-suite run.
% Does not run examples or overwrite historical outputs. Actual engineering,
% GUI, MAT and process evidence is reported separately in v0.21-validation.md.
root=fileparts(fileparts(mfilename('fullpath'))); old=path;
cleanup=onCleanup(@()path(old)); addpath(fullfile(root,'src'),fullfile(root,'app'));
assert(fsd.version()=="0.21.0");
files=[dir(fullfile(root,'src','**','*.m'));dir(fullfile(root,'app','**','*.m')); ...
    dir(fullfile(root,'tests','**','*.m'));dir(fullfile(root,'examples','**','*.m'));dir(fullfile(root,'*.m'))];
analyzerCount=0;
for j=1:numel(files)
    messages=checkcode(fullfile(files(j).folder,files(j).name),'-id'); analyzerCount=analyzerCount+numel(messages);
    for message=messages', fprintf('ANALYZER %s:%d %s\n',files(j).name,message.line,message.message); end
end
assert(analyzerCount==0,'fsd:tests:Analyzer','Resolve Analyzer messages before claiming static verification.');
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
suite=matlab.unittest.TestSuite.fromFolder(fullfile(root,'tests'),'IncludingSubfolders',true);
names=string({suite.Name})'; assert(numel(unique(names))==numel(names));
report=struct('version',fsd.version(),'release',string(version('-release')), ...
    'analyzerCount',analyzerCount,'analyzerFiles',numel(files),'moduleDependencies',edges,'testNames',names);
fprintf('V21_STATIC_PASS ANALYZER=%d/%d EDGES=%d INVENTORY=%d (not executions)\n', ...
    analyzerCount,numel(files),size(edges,1),numel(names));
end
