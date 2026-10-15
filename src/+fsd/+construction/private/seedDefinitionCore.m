function result = seedDefinitionCore(input)
%SEEDDEFINITIONCORE Progressive plain records with explicit family/symmetry.
d=struct('id',"",'description',"",'family',"UNSELECTED",'cornerId',"", ...
    'symmetry',"NONE",'parameters',{{}},'rightParameters',{{}},'constraints',{{}});
seedRequire(isstruct(input) && isscalar(input) && all(isfield(input,{'id','cornerId'})) && ...
    all(ismember(string(fieldnames(input)),string(fieldnames(d)))), 'Invalid parametric definition fields.');
for name=string(fieldnames(input))', d.(name)=input.(name); end
for name=["id","description","family","cornerId","symmetry"]
    v=string(d.(name)); seedRequire(isscalar(v) && ~ismissing(v),'Scalar definition text required.'); d.(name)=v;
end
seedRequire(~isempty(regexp(d.id,'^[A-Z][A-Z0-9_]*$','once')),'Canonical definition ID required.');
seedRequire(ismember(d.cornerId,["FL","FR","RL","RR","FRONT"]),'Unsupported corner/axle.');
seedRequire(ismember(d.symmetry,["NONE","MIRROR_FL"]) && ...
    (d.cornerId=="FRONT" || d.symmetry=="NONE"),'Explicit symmetry only applies to FRONT.');
if d.cornerId~="FRONT" || d.symmetry=="MIRROR_FL", seedRequire(isempty(d.rightParameters),'Unexpected opposite-side parameters.'); end
corner=d.cornerId; if corner=="FRONT", corner="FL"; end
d.parameters=checkParameters(d.parameters,corner);
d.rightParameters=checkParameters(d.rightParameters,'FR');
seedRequire(iscell(d.constraints) && (isvector(d.constraints) || isempty(d.constraints)), 'Constraint cell vector required.');
d.constraints=d.constraints(:); ids=strings(numel(d.constraints),1);
corners=corner; if d.cornerId=="FRONT", corners=["FL","FR"]; end
for j=1:numel(d.constraints)
    fsd.model.validateDesignConstraint(d.constraints{j}); q=d.constraints{j}.definitionSI;
    seedRequire(ismember(q.scope.cornerId,corners),'Constraint belongs to another corner.'); ids(j)=q.id;
end
seedRequire(numel(unique(ids))==numel(ids),'Duplicate constraint IDs.'); [~,order]=sort(ids); d.constraints=d.constraints(order);
seedPlainData(d); physical=rmfield(d,'description');
for name=["parameters","rightParameters"]
    ps=d.(name); identities=cell(numel(ps),1);
    for j=1:numel(ps), p=ps{j}.identity; p.definitionSI=rmfield(p.definitionSI,'description'); identities{j}=p; end
    physical.(name)=identities;
end
physical.constraints=cellfun(@(p)p.identity,d.constraints,'UniformOutput',false);
result=struct('schemaVersion',"0.17.0",'kind',"ParametricSeedDefinition",'definitionSI',d, ...
    'identity',struct('schemaVersion',"0.17.0",'kind',"ParametricSeedDefinitionIdentity",'definitionSI',physical));
end

function ps = checkParameters(ps,corner)
seedRequire(iscell(ps) && (isvector(ps) || isempty(ps)),'Parameter cell vector required.'); ps=ps(:);
catalog=fsd.construction.seedParameterCatalog(); ids=strings(numel(ps),1);
for j=1:numel(ps)
    fsd.model.validateDesignParameter(ps{j}); p=ps{j}.definitionSI; k=find(string({catalog.id})==p.id);
    seedRequire(isscalar(k) && p.quantity==catalog(k).quantity && p.binding=="NONE" && ...
        isequaln(p.scope,fsd.model.designScope('COMPONENT','PARAMETRIC_SEED',corner)), 'Parameter catalog/scope mismatch.');
    ids(j)=p.id;
end
seedRequire(numel(unique(ids))==numel(ids),'Duplicate parameter IDs.'); [~,order]=sort(ids); ps=ps(order);
end
