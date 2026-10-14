function project = attachEngineeringResult(project,result)
%ATTACHENGINEERINGRESULT Retain validated historical evidence without changing config.
fsd.project.validateEngineeringProject(project); fsd.project.validateEngineeringResult(result);
projectRequire(result.projectId==project.id && result.projectRevision<=project.definition.revision, ...
    'Cannot attach cross-project or future-revision evidence.');
d=project.definition; d.results{end+1,1}=result; project=projectCore(d);
end
