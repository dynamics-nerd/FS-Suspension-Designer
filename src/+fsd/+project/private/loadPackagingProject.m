function project=loadPackagingProject(envelope,file,variables)
%LOADPACKAGINGPROJECT Restore exactly one canonical project from native MAT.
expected=["kind";"schemaVersion";"encoding";"configuration";"resultNames";"resultShape"];
projectRequire(isstruct(envelope) && isscalar(envelope) && ...
    isequal(sort(string(fieldnames(envelope))),sort(expected)) && ...
    isequal(envelope.kind,'FsdEngineeringProjectStorage') && ...
    isequal(envelope.schemaVersion,'0.19.0') && ...
    (isequal(envelope.encoding,'FSD_TEXT_V1') || isequal(envelope.encoding,'FSD_VALUE_GRAPH_V1')), ...
    'Unsupported Packaging MAT storage header.');
names=envelope.resultNames;
projectRequire(iscell(names) && isrow(names) && all(cellfun(@ischar,names)), 'Invalid MAT record names.');
canonical=arrayfun(@(j)sprintf('FSD_RESULT_%06d',j),1:numel(names),'UniformOutput',false);
projectRequire(isequal(names,canonical) && isequal(envelope.resultShape,[numel(names),1]) && ...
    isequal(sort(string({variables.name})),sort(["envelope",string(names)])), 'MAT record inventory/shape mismatch.');
decoder=@fsd.project.decodeStorageValue;
if isequal(envelope.encoding,'FSD_VALUE_GRAPH_V1'), decoder=@fsd.project.decodeStorageGraph; end
project=decoder(envelope.configuration);
projectRequire(isstruct(project) && isscalar(project) && isfield(project,'definition') && ...
    isstruct(project.definition) && isfield(project.definition,'results') && ...
    isequal(project.definition.results,cell(0,1)), 'Invalid stored project configuration.');
records=cell(envelope.resultShape);
for j=1:numel(names)
    stored=load(file,names{j}); records{j}=decoder(stored.(names{j}));
end
project.definition.results=records;
fsd.project.validateEngineeringProject(project);
end
