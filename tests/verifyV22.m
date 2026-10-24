function report=verifyV22()
%VERIFYV22 Analyzer, module DAG and inventory only; not test execution.
root=fileparts(fileparts(mfilename('fullpath'))); old=path; cleanup=onCleanup(@()path(old));
addpath(fullfile(root,'src')); assert(fsd.version()=="0.22.0");
files=[dir(fullfile(root,'src','**','*.m'));dir(fullfile(root,'app','**','*.m')); ...
    dir(fullfile(root,'tests','**','*.m'));dir(fullfile(root,'examples','**','*.m'));dir(fullfile(root,'*.m'))];
count=0; edges=strings(0,2);
for j=1:numel(files)
    f=fullfile(files(j).folder,files(j).name); messages=checkcode(f,'-id'); count=count+numel(messages);
    for m=messages', fprintf('ANALYZER %s:%d %s %s\n',f,m.line,m.id,m.message); end
    token=regexp(f,'[\\/]\+fsd[\\/]\+(\w+)','tokens','once');
    if isempty(token), continue; end
    code=regexprep(fileread(f),'(?m)^[ \t]*%[^\r\n]*','');
    assert(~contains(code,'fsdui.'),'Core must not depend on UI.');
    calls=regexp(code,'\<fsd\.([A-Za-z]+)\.[A-Za-z]\w*\s*\(','tokens'); targets=unique(string([calls{:}]));
    edges=[edges;[repmat(string(token{1}),numel(targets),1),targets(:)]]; %#ok<AGROW> Static file inventory.
end
edges=unique(edges,'rows'); edges=edges(edges(:,1)~=edges(:,2),:);
assert(isdag(digraph(edges(:,1),edges(:,2))));
assert(~any((edges(:,1)=="kinematics"&edges(:,2)=="rules")|(edges(:,1)=="rules"&edges(:,2)=="kinematics")));
assert(~any(edges(:,1)=="export"&edges(:,2)=="kinematics"));
assert(~any(edges(:,1)=="tire"&ismember(edges(:,2),["project","analysis","kinematics","geometry"])));
suite=matlab.unittest.TestSuite.fromFolder(fullfile(root,'tests'),'IncludingSubfolders',true);
names=string({suite.Name})'; assert(numel(unique(names))==numel(names));
report=struct('version',fsd.version(),'analyzerCount',count,'analyzerFiles',numel(files), ...
    'moduleDependencies',edges,'testNames',names);
fprintf('V22_STATIC ANALYZER=%d/%d EDGES=%d INVENTORY=%d\n',count,numel(files),size(edges,1),numel(names));
assert(count==0,'fsd:test:Analyzer','Analyzer messages require review.');
end
