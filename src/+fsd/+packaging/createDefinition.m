function definition=createDefinition(input)
%CREATEDEFINITION Explicit volume/pair/region contract. All lengths already SI.
require(isstruct(input) && isscalar(input) && ...
    isequal(sort(string(fieldnames(input))),sort(["id";"volumes";"pairs";"regions"])), ...
    'Supply id, volumes, pairs and regions.');
d=input; d.id=text(d.id);
require(~isempty(regexp(d.id,'^[A-Z][A-Z0-9_]*$','once')),'Canonical definition ID required.');
for name=["volumes","pairs","regions"]
    require(iscell(d.(name)) && (isvector(d.(name)) || isempty(d.(name))),name+" must be a cell vector.");
    d.(name)=d.(name)(:);
end
ids=strings(numel(d.volumes),1);
for j=1:numel(ids), fsd.packaging.validateVolume(d.volumes{j}); ids(j)=d.volumes{j}.definitionSI.id; end
require(numel(unique(ids))==numel(ids),'Duplicate volume IDs.');
pairIds=strings(numel(d.pairs),1); pairKeys=strings(numel(d.pairs),1);
for j=1:numel(d.pairs)
    p=d.pairs{j}; fields=["id";"first";"second";"requiredClearance_m";"exception"];
    require(isstruct(p) && isscalar(p) && isequal(sort(string(fieldnames(p))),sort(fields)),'Invalid pair fields.');
    for name=["id","first","second"], p.(name)=text(p.(name)); end
    require(p.first~=p.second && all(ismember([p.first;p.second],ids)),'Pair requires two distinct declared volumes.');
    nonnegative(p.requiredClearance_m,'Explicit nonnegative required clearance required.');
    a=d.volumes{ids==p.first}.definitionSI; b=d.volumes{ids==p.second}.definitionSI;
    require(a.role=="OCCUPIED" && b.role=="OCCUPIED",'Collision pairs require occupied material, not free rim interiors.');
    require(isequaln(a.frame,b.frame),'Pair volumes must share the complete parent frame.');
    if ~isempty(p.exception)
        e=p.exception;
        require(isstruct(e) && isscalar(e) && isequal(sort(string(fieldnames(e))), ...
            sort(["id";"firstComponent";"secondComponent";"reason";"source"])), 'Invalid exception fields.');
        for name=string(fieldnames(e))', e.(name)=text(e.(name)); end
        require(e.firstComponent==a.componentId && e.secondComponent==b.componentId,'Exception component IDs differ from its exact pair.');
        forbidden=["TIRE_ENVELOPE","RIM_MATERIAL","RIM_INTERIOR","OBSTACLE"];
        require((a.componentType=="JOINT" || b.componentType=="JOINT") && ...
            ~any(ismember([a.componentType;b.componentType],forbidden)), ...
            'Joint exception cannot hide tube/rim/chassis interference. Split local joint envelopes explicitly.');
        p.exception=e;
    end
    pairIds(j)=p.id; pairKeys(j)=join(sort([p.first;p.second]),"|"); d.pairs{j}=p;
end
require(numel(unique(pairIds))==numel(pairIds) && numel(unique(pairKeys))==numel(pairKeys),'Duplicate pair IDs or reversed pairs.');
regionIds=strings(numel(d.regions),1);
for j=1:numel(d.regions)
    r=d.regions{j}; fields=["id";"cornerId";"pointId";"mode";"volumeId";"target_m"; ...
        "tolerance_m";"clearance_m";"source";"provenance"];
    require(isstruct(r) && isscalar(r) && isequal(sort(string(fieldnames(r))),sort(fields)),'Invalid region fields.');
    for name=["id","cornerId","pointId","mode","source","provenance"], r.(name)=text(r.(name)); end
    r.volumeId=string(r.volumeId);
    require(isscalar(r.volumeId) && ~ismissing(r.volumeId) && ismember(r.cornerId,["FL","FR","RL","RR"]) && ...
        startsWith(r.pointId,r.cornerId+"_") && ismember(r.mode,["FIXED","INSIDE","OUTSIDE"]),'Invalid region binding/mode.');
    if r.mode=="FIXED"
        require(isnumeric(r.target_m) && isreal(r.target_m) && isequal(size(r.target_m),[1 3]) && all(isfinite(r.target_m)) && ...
            strlength(r.volumeId)==0 && isempty(r.clearance_m),'FIXED needs explicit target/tolerance, not a volume.');
        nonnegative(r.tolerance_m,'Explicit FIXED comparison tolerance required.');
    else
        require(ismember(r.volumeId,ids) && isempty(r.target_m) && isempty(r.tolerance_m),'Region requires a declared volume, not FIXED fields.');
        v=d.volumes{ids==r.volumeId}.definitionSI;
        require(v.binding.mode=="FIXED",'Design regions must be explicitly fixed in the declared frame.');
        nonnegative(r.clearance_m,'Explicit region clearance required.');
    end
    regionIds(j)=r.id; d.regions{j}=r;
end
require(numel(unique(regionIds))==numel(regionIds),'Duplicate region IDs.');
definition=struct('schemaVersion',"0.19.0",'kind',"PackagingDefinition",'units',"SI",'definitionSI',d,'identity',d);
end
function require(condition,message)
assert(condition,'fsd:packaging:InvalidDefinition','%s',message);
end
function s=text(value)
require((ischar(value) || isstring(value)) && isscalar(string(value)) && ~ismissing(string(value)), 'Explicit scalar text required.');
s=string(value); require(strlength(strtrim(s))>0,'Nonempty text required.');
end
function nonnegative(v,message)
require(isnumeric(v) && isreal(v) && isscalar(v) && isfinite(v) && v>=0,message);
end
