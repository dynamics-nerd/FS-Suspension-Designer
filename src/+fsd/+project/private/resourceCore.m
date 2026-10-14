function resources = resourceCore(input)
%RESOURCECORE Optional native resources, canonical ordering and association checks.
resources=struct('geometries',{{}},'steerings',{{}},'actuations',{{}},'mechanicals',{{}});
projectRequire(isstruct(input) && isscalar(input) && all(ismember(string(fieldnames(input)), ...
    string(fieldnames(resources)))),'Invalid resource registry.');
for name=string(fieldnames(input))', resources.(name)=input.(name); end
for name=string(fieldnames(resources))'
    entries=resources.(name); projectRequire(iscell(entries) && (isvector(entries) || isempty(entries)), ...
        'Resources must be cell vectors.'); entries=entries(:); ids=strings(numel(entries),1);
    for j=1:numel(entries)
        r=entries{j};
        switch name
            case "geometries", fsd.model.validateDoubleWishboneGeometry(r); ids(j)=r.cornerId;
            case "steerings", fsd.model.validateSteeringSystemGeometry(r); ids(j)="FRONT";
            case "actuations", fsd.model.validateActuationGeometry(r); ids(j)=r.cornerId;
            case "mechanicals", fsd.model.validateSpringDamperModel(r); ids(j)=r.cornerId;
        end
    end
    projectRequire(numel(unique(ids))==numel(ids),'Duplicate resource IDs.');
    [~,order]=sort(ids); resources.(name)=entries(order);
end
for j=1:numel(resources.actuations)
    a=resources.actuations{j}; g=resourceFind(resources,'geometries',a.cornerId);
    if ~isempty(g), projectRequire(isequaln(a.cornerGeometryIdentity,fsd.model.geometryIdentity(g)), ...
            'Actuation and corner seed identities disagree.'); end
end
for j=1:numel(resources.mechanicals)
    m=resources.mechanicals{j}; a=resourceFind(resources,'actuations',m.cornerId);
    if ~isempty(a), projectRequire(isequaln(m.actuationIdentity,a.identity),'Mechanical/actuation identities disagree.'); end
end
for j=1:numel(resources.steerings)
    s=resources.steerings{j};
    for side=["leftGeometry","rightGeometry"]
        seed=s.frontAxleGeometry.(side); g=resourceFind(resources,'geometries',seed.cornerId);
        if ~isempty(g), projectRequire(isequaln(fsd.model.geometryIdentity(seed),fsd.model.geometryIdentity(g)), ...
                'Steering and corner seed identities disagree.'); end
    end
end
end
