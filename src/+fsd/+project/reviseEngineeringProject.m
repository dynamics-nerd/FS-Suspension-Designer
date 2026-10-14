function revised = reviseEngineeringProject(project,patch)
%REVISEENGINEERINGPROJECT New configuration; historical evidence is not rewritten.
fsd.project.validateEngineeringProject(project);
allowed=["concept","name","description","resources","scenarios"];
projectRequire(isstruct(patch) && isscalar(patch) && all(ismember(string(fieldnames(patch)),allowed)), ...
    'Only engineering configuration fields may be revised.');
d=project.definition;
for name=string(fieldnames(patch))', d.(name)=patch.(name); end
candidate=projectCore(d); projectRequire(candidate.id==project.id,'Project ID is immutable.');
if isequaln(candidate,project), revised=project; return; end
d.revision=d.revision+1; revised=projectCore(d);
end
