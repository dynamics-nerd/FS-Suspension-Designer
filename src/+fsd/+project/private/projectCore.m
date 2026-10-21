function project = projectCore(input,context)
%PROJECTCORE Canonical configuration identity excludes the historical result ledger.
if nargin<2, context=validationContext(); end
d=struct('concept',[],'name',"",'description',"",'revision',1,'resources',struct(), ...
    'scenarios',{{}},'results',{{}},'derivations',{{}});
projectRequire(isstruct(input) && isscalar(input) && isfield(input,'concept') && ...
    all(ismember(string(fieldnames(input)),string(fieldnames(d)))),'Invalid project fields.');
for name=string(fieldnames(input))', d.(name)=input.(name); end
context.concept(d.concept);
for name=["name","description"], d.(name)=projectText(d.(name),true); end
projectRequire(isnumeric(d.revision) && isreal(d.revision) && isscalar(d.revision) && ...
    isfinite(d.revision) && d.revision>=1 && fix(d.revision)==d.revision,'Positive integer revision required.');
d.resources=context.resources(d.resources);
for name=["scenarios","results","derivations"]
    projectRequire(iscell(d.(name)) && (isvector(d.(name)) || isempty(d.(name))),name+" must be a cell vector.");
    d.(name)=d.(name)(:);
end
ids=strings(numel(d.scenarios),1);
for j=1:numel(d.scenarios), context.scenario(d.scenarios{j}); ids(j)=d.scenarios{j}.definition.id; end
projectRequire(numel(unique(ids))==numel(ids),'Duplicate scenario IDs.'); [~,order]=sort(ids); d.scenarios=d.scenarios(order);
id=d.concept.definitionSI.id;
if isfield(d.resources,'seedBindings')
    for j=1:numel(d.resources.seedBindings)
        b=d.resources.seedBindings{j};
        projectRequire(b.projectId==id && b.projectRevision<=d.revision, 'Cross-project/future seed binding.');
    end
end
resultIds=strings(numel(d.results),1);
for j=1:numel(d.results)
    r=d.results{j}; context.result(r);
    projectRequire(r.projectId==id && r.projectRevision<=d.revision,'Cross-project or future-revision result.');
    resultIds(j)=r.id;
end
projectRequire(numel(unique(resultIds))==numel(resultIds),'Duplicate result IDs.');
[~,order]=sort(resultIds); d.results=d.results(order);
for j=1:numel(d.derivations)
    context.derivation(d.derivations{j});
    projectRequire(d.derivations{j}.concept.definitionSI.id==id,'Cross-project derivation.');
end
% Closed-field composition: concept/resources/scenarios/derivations have full
% plain-data proofs above; resultCore proves every complete result. Header
% fields are explicitly numeric/text. Do not traverse those same trees again.
identity=struct('schemaVersion',"0.16.0",'projectId',id,'revision',d.revision, ...
    'concept',d.concept.identity,'resources',d.resources, ...
    'scenarios',{cellfun(@(s)s.identity,d.scenarios,'UniformOutput',false)});
project=struct('schemaVersion',"0.16.0",'kind',"EngineeringProject",'id',id, ...
    'units',"SI",'coordinateSystem',"X_REAR_Y_RIGHT_Z_UP",'definition',d,'identity',identity);
end
