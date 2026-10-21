function saveEngineeringProject(project,file,overwrite)
%SAVEENGINEERINGPROJECT Versioned MAT; trusted local data, not arbitrary MAT sandbox.
if nargin<3, overwrite=false; end
fsd.project.validateEngineeringProject(project); file=projectText(file);
projectRequire(islogical(overwrite) && isscalar(overwrite),'Explicit logical overwrite policy required.');
projectRequire(endsWith(lower(file),'.mat'),'Project file must have a .mat extension.');
projectRequire(overwrite || ~isfile(file),'Project file already exists; explicit overwrite required.');

packaging=isfield(project.definition.resources,'packaging') || ...
    any(cellfun(@(s)s.definition.engine=="PACKAGING",project.definition.scenarios));
for record=project.definition.results'
    packaging=packaging || record{1}.engine=="PACKAGING" || ...
        isfield(record{1}.projectAtExecution.definition.resources,'packaging');
end
% Native histories also contain deeply repeated snapshots without Packaging.
% Use the same lossless bounded v0.19 envelope; retain the legacy reader and
% legacy writer for non-Packaging projects without a result ledger.
if packaging || ~isempty(project.definition.results)
    savePackagingProject(project,file); return;
end
envelope=struct('kind',"FsdEngineeringProjectFile",'schemaVersion',"0.16.0",'project',project);
save(file,'envelope','-v7');
end
