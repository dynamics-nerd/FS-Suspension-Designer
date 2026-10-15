function seedReferenceCore(parameters)
%SEEDREFERENCECORE Native physical dimension declarations only.
seedRequire(iscell(parameters) && (isvector(parameters) || isempty(parameters)),'Reference parameter cell vector required.');
ids=strings(numel(parameters),1);
for j=1:numel(parameters)
    p=parameters{j}; fsd.model.validateDesignParameter(p); d=p.definitionSI;
    seedRequire(ismember(d.id,["WHEELBASE","FRONT_TRACK","REAR_TRACK"]) && d.quantity=="LENGTH" && ...
        isequaln(d.scope,fsd.model.designScope('VEHICLE','VEHICLE')) && d.binding=="NONE", 'Invalid concept reference quantity.');
    ids(j)=d.id;
end
seedRequire(numel(unique(ids))==numel(ids),'Duplicate reference dimensions.');
seedPlainData(parameters);
end
