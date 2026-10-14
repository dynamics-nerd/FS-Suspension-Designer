function concept = conceptCore(input)
%CONCEPTCORE Progressive vehicle information, not a physical VehicleParameters clone.
d=struct('id',"",'vehicleName',"",'description',"",'category',"UNSPECIFIED", ...
    'massConvention',"UNSPECIFIED",'parameters',{{}},'architectures',struct(), 'ruleReference',struct());
projectRequire(isstruct(input) && isscalar(input) && isfield(input,'id') && ...
    all(ismember(string(fieldnames(input)),string(fieldnames(d)))),'Invalid vehicle concept fields.');
for name=string(fieldnames(input))', d.(name)=input.(name); end
d.id=projectText(d.id); projectRequire(~isempty(regexp(d.id,'^[A-Z][A-Z0-9_]*$','once')),'Canonical project ID required.');
for name=["vehicleName","description"], d.(name)=projectText(d.(name),true); end
d.category=projectText(d.category); d.massConvention=projectText(d.massConvention);
projectRequire(ismember(d.massConvention,["UNSPECIFIED","EXCLUDES_DRIVER","INCLUDES_DRIVER"]),'Unknown mass inclusion convention.');
projectRequire(iscell(d.parameters) && (isvector(d.parameters) || isempty(d.parameters)),'Concept parameter cell vector required.');
d.parameters=d.parameters(:); ids=strings(numel(d.parameters),1);
for j=1:numel(d.parameters), fsd.project.validateConceptParameter(d.parameters{j}); ids(j)=d.parameters{j}.id; end
projectRequire(numel(unique(ids))==numel(ids),'Duplicate concept parameter IDs.'); [~,order]=sort(ids); d.parameters=d.parameters(order);
a=struct('frontSuspension',"UNSELECTED",'rearSuspension',"UNSELECTED", ...
    'frontActuation',"UNSELECTED",'rearActuation',"UNSELECTED");
projectRequire(isstruct(d.architectures) && isscalar(d.architectures) && ...
    all(ismember(string(fieldnames(d.architectures)),string(fieldnames(a)))),'Invalid architecture fields.');
for name=string(fieldnames(d.architectures))', a.(name)=d.architectures.(name); end
for name=string(fieldnames(a))'
    a.(name)=projectText(a.(name));
    projectRequire(~isempty(regexp(a.(name),'^[A-Z][A-Z0-9_]*$','once')),'Architecture choice must be an explicit ID.');
end
d.architectures=a;
projectRequire(isstruct(d.ruleReference) && isscalar(d.ruleReference),'Rule reference must be a scalar struct.');
if ~isempty(fieldnames(d.ruleReference))
    projectRequire(all(isfield(d.ruleReference,{'organizer','version','source','status'})),'Rule version/source/status required.');
    for name=["organizer","version","source","status"], d.ruleReference.(name)=projectText(d.ruleReference.(name)); end
end
plainProjectData(d);
identity=d; identity=rmfield(identity,{'vehicleName','description'});
identity.parameters=cellfun(@(p)p.identity,d.parameters,'UniformOutput',false);
concept=struct('schemaVersion',"0.16.0",'kind',"VehicleConcept",'coordinateSystem',"X_REAR_Y_RIGHT_Z_UP", ...
    'definitionSI',d,'identity',struct('schemaVersion',"0.16.0",'kind',"VehicleConceptIdentity",'definitionSI',identity));
end
