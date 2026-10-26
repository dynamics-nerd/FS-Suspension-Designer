function definition=createAntiRollBarDefinition(input)
%CREATEANTIROLLBARDEFINITION Explicit material radii/obstacles and named ARB endpoints.
fields=["id";"frame";"components";"obstacles";"pairs";"provenance"];
assert(isstruct(input)&&isscalar(input)&&isequal(sort(string(fieldnames(input))),sort(fields)), ...
    'fsd:packaging:InvalidAntiRollBar','Supply exactly id/frame/components/obstacles/pairs/provenance.');
d=input; d.id=string(d.id); d.provenance=string(d.provenance);
need(isscalar(d.id)&&~ismissing(d.id)&&~isempty(regexp(d.id,'^[A-Z][A-Z0-9_]*$','once'))&& ...
    isscalar(d.provenance)&&~ismissing(d.provenance)&&strlength(d.provenance)>0,'Explicit ID and provenance required.');
f=d.frame;
need(isstruct(f)&&isscalar(f)&&isequal(sort(string(fieldnames(f))),["axisConvention";"id";"originDescription"])&& ...
    string(f.axisConvention)=="X_REAR_Y_RIGHT_Z_UP",'Native complete parent frame required.');
for key=string(fieldnames(f))', need(isscalar(string(f.(key)))&&strlength(string(f.(key)))>0,'Nonempty frame fields required.'); end
for key=["components","obstacles","pairs"]
    need(iscell(d.(key))&&(isvector(d.(key))||isempty(d.(key))),'Cell-vector declarations required.'); d.(key)=d.(key)(:);
end
ids=strings(0,1);
for k=1:numel(d.components)
    c=d.components{k};
    need(isstruct(c)&&isscalar(c)&&isequal(sort(string(fieldnames(c))), ...
        ["firstPoint";"id";"radius_m";"secondPoint";"shape";"source"]),'Invalid component fields.');
    for key=["id","firstPoint","secondPoint","shape","source"], c.(key)=string(c.(key)); need(isscalar(c.(key))&&~ismissing(c.(key))&&strlength(c.(key))>0,'Explicit component text required.'); end
    need(~isempty(regexp(c.id,'^[A-Z][A-Z0-9_]*$','once'))&&ismember(c.shape,["CAPSULE","SPHERE"])&& ...
        startsWith(c.firstPoint,'ARB_')&&startsWith(c.secondPoint,'ARB_'),'Explicit ARB point aliases and supported primitive required.');
    need(c.shape~="SPHERE"||c.firstPoint==c.secondPoint,'Sphere centre must be a single declared point.');
    need(isnumeric(c.radius_m)&&isreal(c.radius_m)&&(isempty(c.radius_m)||(isscalar(c.radius_m)&&isfinite(c.radius_m)&&c.radius_m>0)),'Radius is positive or unknown.');
    c.radius_m=double(c.radius_m); d.components{k}=c; ids(end+1,1)=c.id; %#ok<AGROW> Explicit declared components.
end
for k=1:numel(d.obstacles)
    v=d.obstacles{k}; fsd.packaging.validateVolume(v); vd=v.definitionSI;
    need(vd.binding.mode=="FIXED"&&vd.role=="OCCUPIED"&&isequaln(vd.frame,d.frame),'Obstacle must be explicit fixed occupied geometry in this frame.');
    ids(end+1,1)=vd.id; %#ok<AGROW> Explicit obstacles only.
end
need(numel(unique(ids))==numel(ids),'Duplicate volume IDs.'); pairIds=strings(0,1); pairKeys=strings(0,1);
for k=1:numel(d.pairs)
    p=d.pairs{k}; need(isstruct(p)&&isscalar(p)&&isequal(sort(string(fieldnames(p))), ...
        ["first";"id";"requiredClearance_m";"second"]),'Invalid pair fields.');
    for key=["id","first","second"], p.(key)=string(p.(key)); need(isscalar(p.(key))&&~ismissing(p.(key)),'Scalar pair IDs required.'); end
    need(strlength(p.id)>0&&p.first~=p.second&&all(ismember([p.first;p.second],ids)),'Pair must select distinct declared volumes.');
    need(isnumeric(p.requiredClearance_m)&&isreal(p.requiredClearance_m)&&(isempty(p.requiredClearance_m)|| ...
        (isscalar(p.requiredClearance_m)&&isfinite(p.requiredClearance_m)&&p.requiredClearance_m>=0)),'Clearance is explicit nonnegative or unknown.');
    p.requiredClearance_m=double(p.requiredClearance_m); d.pairs{k}=p; pairIds(end+1,1)=p.id; %#ok<AGROW>
    pairKeys(end+1,1)=join(sort([p.first;p.second]),'|'); %#ok<AGROW>
end
need(numel(unique(pairIds))==numel(pairIds)&&numel(unique(pairKeys))==numel(pairKeys),'Duplicate pair.');
definition=struct('schemaVersion',"0.23.0",'kind',"AntiRollBarPackagingDefinition",'definition',d,'identity',d);
end
function need(ok,message)
assert(ok,'fsd:packaging:InvalidAntiRollBar',message);
end
