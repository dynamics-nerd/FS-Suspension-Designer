function scenario = scenarioCore(input)
%SCENARIOCORE Closed orchestration contract with historical specifications.
d=struct('id',"",'name',"",'description',"",'engine',"",'scope',[], ...
    'plan',struct(),'options',struct(),'specification',[],'symmetryLinks',strings(0,2), ...
    'targetOrigins',{{}},'conceptDependencies',strings(0,1),'inputs',struct());
projectRequire(isstruct(input) && isscalar(input) && all(isfield(input,{'id','engine','scope'})) && ...
    all(ismember(string(fieldnames(input)),string(fieldnames(d)))),'Invalid scenario fields.');
for name=string(fieldnames(input))', d.(name)=input.(name); end
for name=["id","engine"], d.(name)=projectText(d.(name)); end
projectRequire(~isempty(regexp(d.id,'^[A-Z][A-Z0-9_]*$','once')),'Canonical scenario ID required.');
for name=["name","description"], d.(name)=projectText(d.(name),true); end
scope=d.scope; projectRequire(isstruct(scope) && isscalar(scope) && all(isfield(scope,{'kind','id','cornerId'})), ...
    'Native design scope required.');
projectRequire(isequaln(scope,fsd.model.designScope(scope.kind,scope.id,scope.cornerId)) && ...
    ismember(scope.kind,["VEHICLE","AXLE","CORNER"]),'Scenario requires native vehicle/axle/corner scope.');
for name=["plan","options","inputs"]
    projectRequire(isstruct(d.(name)) && isscalar(d.(name)),name+" must be a scalar struct.");
end
projectRequire(isstring(d.symmetryLinks) && size(d.symmetryLinks,2)==2,'Native symmetry links required.');
projectRequire(isstring(d.conceptDependencies),'Concept dependencies must be string IDs.');
d.conceptDependencies=sort(unique(d.conceptDependencies(:)));
catalog=fsd.project.conceptParameterCatalog();
projectRequire(all(ismember(d.conceptDependencies,string({catalog.id}))), ...
    'Unknown concept dependency.');
projectRequire(iscell(d.targetOrigins) && (isvector(d.targetOrigins) || isempty(d.targetOrigins)), ...
    'Target origin cell vector required.');
d.targetOrigins=d.targetOrigins(:); targetIds=strings(0,1);
if ~isempty(d.specification)
    fsd.model.validateDesignSpecification(d.specification);
    ts=d.specification.definitionSI.targets.definitionSI.targets;
    targetIds=cellfun(@(t)t.definitionSI.id,ts);
end
originIds=strings(numel(d.targetOrigins),1);
for j=1:numel(d.targetOrigins)
    o=d.targetOrigins{j}; projectRequire(isstruct(o) && isscalar(o) && ...
        isequal(sort(string(fieldnames(o))),sort(["targetId";"kind";"reference";"note"])), 'Invalid target origin.');
    for name=["targetId","kind","reference","note"], o.(name)=projectText(o.(name),true); end
    projectRequire(ismember(o.targetId,targetIds) && ismember(o.kind,["USER_DEFINED","DECLARED_REFERENCE", ...
        "SUPPORTED_MODEL","ASSUMED","PENDING_JUSTIFICATION"]),'Invalid target origin ID/kind.');
    projectRequire(~ismember(o.kind,["DECLARED_REFERENCE","SUPPORTED_MODEL"]) || strlength(o.reference)>0, ...
        'Reference/model-derived targets require a declared reference.');
    originIds(j)=o.targetId; d.targetOrigins{j}=o;
end
projectRequire(numel(unique(originIds))==numel(originIds),'Duplicate target origin IDs.');
[~,order]=sort(originIds); d.targetOrigins=d.targetOrigins(order);
plainProjectData(d); identity=rmfield(d,{'name','description'});
if ~isempty(d.specification), identity.specification=d.specification.identity; end
scenario=struct('schemaVersion',"0.16.0",'kind',"EngineeringScenario",'definition',d, ...
    'identity',struct('schemaVersion',"0.16.0",'kind',"EngineeringScenarioIdentity",'definition',identity));
end
