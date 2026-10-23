function output=guidedGlobalStaticExample(file)
%GUIDEDGLOBALSTATICEXAMPLE Explicit synthetic benchmark; never loaded by the app.
% New optional MAT destination. Records timings for preparation, execution,
% compatibility/history and storage; Windows memory fields are not peak RSS.
if nargin<1, file=""; end
started=tic; before=[]; if ispc, before=memory; end
[p,d]=globalStaticGuidedInputs(); c=fsdui.Controller(p); cleanup=onCleanup(@()c.close());
stages=timed(c,'GLOBAL_CONFIG',struct('definition',d));
assert(c.LastValue.status=="READY");
stages(end+1)=timed(c,'GLOBAL_RUN',struct('scenarioId',d.id,'resultId',"GLOBAL_BASE"));
first=c.LastValue;
% Deliberate explicit sensitivity, not measured vehicle data or an optimal setup.
d.plan.systemOptions.roadHeight_m=.001;
stages(end+1)=timed(c,'GLOBAL_CONFIG',struct('definition',d));
stages(end+1)=timed(c,'GLOBAL_RUN',struct('scenarioId',d.id,'resultId',"GLOBAL_ROAD_CHANGE"));
second=c.LastValue;
assert(numel(c.Project.definition.results)==2);
assert(fsd.project.resultCompatibility(first,c.Project).status=="STALE");
assert(fsd.project.resultCompatibility(second,c.Project).status=="CURRENT_EXECUTION");
if strlength(string(file))>0
    stages(end+1)=timed(c,'SAVE',struct('file',string(file),'overwrite',false));
    expected=c.Project; stages(end+1)=timed(c,'LOAD',struct('file',string(file)));
    assert(isequaln(c.Project,expected));
end
after=[]; if ispc, after=memory; end
output=struct('project',c.Project,'first',first,'second',second,'stages',stages, ...
    'elapsed_s',toc(started),'memoryBefore',before,'memoryAfter',after);
fprintf('GLOBAL_GUIDED_EXAMPLE elapsed_s=%.6f records=%d\n',output.elapsed_s,numel(c.Project.definition.results));
end
function s=timed(c,action,args)
timer=tic; c.run(action,args,false); s=struct('action',string(action),'elapsed_s',toc(timer));
end
