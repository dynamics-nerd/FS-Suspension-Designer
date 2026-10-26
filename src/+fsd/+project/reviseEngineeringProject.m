function revised = reviseEngineeringProject(project,patch)
%REVISEENGINEERINGPROJECT New configuration; historical evidence is not rewritten.
context=validationContext(); context.project(project);
allowed=["concept","name","description","resources","scenarios"];
projectRequire(isstruct(patch) && isscalar(patch) && all(ismember(string(fieldnames(patch)),allowed)), ...
    'Only engineering configuration fields may be revised.');
d=project.definition;
for name=string(fieldnames(patch))', d.(name)=patch.(name); end
candidate=projectCore(d,context); projectRequire(candidate.id==project.id,'Project ID is immutable.');
if isfield(project.definition.resources,'tires')
    for old=project.definition.resources.tires'
        t=old{1}; retained=fsd.project.findTire(candidate,t.definition.id,t.definition.revision);
        projectRequire(isequaln(retained,t),'Registered tire revisions are immutable; append a new revision.');
    end
end
if isfield(project.definition.resources,'antiRollBars')
    for old=project.definition.resources.antiRollBars'
        b=old{1}; retained=fsd.project.findAntiRollBar(candidate,b.definition.id,b.definition.revision);
        projectRequire(isequaln(retained,b),'Registered ARB revisions are immutable; append a new revision.');
    end
end
if isequaln(candidate,project), revised=project; return; end
d.revision=d.revision+1; revised=projectCore(d,context);
end
