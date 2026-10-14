function project = loadEngineeringProject(file)
%LOADENGINEERINGPROJECT Reconstruct trusted MAT records; never run physical solves.
file=projectText(file); variables=whos('-file',file);
projectRequire(any(string({variables.name})=="envelope"), ...
    'No engineering project envelope; use historical APIs for old synthesis MATs.');
stored=load(file,'envelope');
e=stored.envelope; plainProjectData(e);
projectRequire(isstruct(e) && isscalar(e) && isequal(sort(string(fieldnames(e))), ...
    sort(["kind";"schemaVersion";"project"])) && e.kind=="FsdEngineeringProjectFile" && ...
    e.schemaVersion=="0.16.0",'Unsupported or invalid project MAT schema.');
project=e.project; fsd.project.validateEngineeringProject(project);
end
