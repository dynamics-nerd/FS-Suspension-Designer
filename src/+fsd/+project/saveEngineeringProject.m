function saveEngineeringProject(project,file,overwrite)
%SAVEENGINEERINGPROJECT Versioned MAT; trusted local data, not arbitrary MAT sandbox.
if nargin<3, overwrite=false; end
fsd.project.validateEngineeringProject(project); file=projectText(file);
projectRequire(islogical(overwrite) && isscalar(overwrite),'Explicit logical overwrite policy required.');
projectRequire(endsWith(lower(file),'.mat'),'Project file must have a .mat extension.');
projectRequire(overwrite || ~isfile(file),'Project file already exists; explicit overwrite required.');
envelope=struct('kind',"FsdEngineeringProjectFile",'schemaVersion',"0.16.0",'project',project);
save(file,'envelope','-v7');
end
