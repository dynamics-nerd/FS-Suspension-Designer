function resources = resourceCore(input)
%RESOURCECORE Optional native resources, canonical ordering and association checks.
resources=struct('geometries',{{}},'steerings',{{}},'actuations',{{}},'mechanicals',{{}});
if isfield(input,'seedBindings'), resources.seedBindings={}; end
if isfield(input,'packaging'), resources.packaging={}; end
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
            case "seedBindings", validateSeedBinding(r); ids(j)=r.scenarioId;
            case "packaging", fsd.packaging.validateDefinition(r); ids(j)=r.definitionSI.id;
        end
    end
    projectRequire(numel(unique(ids))==numel(ids),'Duplicate resource IDs.');
    [~,order]=sort(ids); resources.(name)=entries(order);
end
if isfield(resources,'seedBindings')
    boundCorners=strings(numel(resources.geometries),1); boundCount=0;
    for j=1:numel(resources.seedBindings)
        b=resources.seedBindings{j};
        for k=1:numel(b.construction.geometries)
            original=b.construction.geometries{k}; g=resourceFind(resources,'geometries',original.cornerId);
            projectRequire(~isempty(g) && isequaln(g,original), 'Registered geometry differs from its parametric origin binding.');
            projectRequire(~ismember(original.cornerId,boundCorners(1:boundCount)),'Corner has multiple parametric origins.');
            boundCount=boundCount+1; boundCorners(boundCount)=original.cornerId;
        end
        if ~isempty(b.construction.axle)
            refs=b.construction.referenceParameters; index=cellfun(@(p)p.definitionSI.id=="WHEELBASE",refs);
            wb=refs{index}.definitionSI.value; tol=fsd.model.numericTolerances();
            for k=1:numel(resources.steerings)
                rear=resources.steerings{k}.rearAxleX_m;
                projectRequire(abs(rear-wb)<=tol.AbsTol_m+tol.RelTol*max([1,abs(rear),abs(wb)]), ...
                    'Steering rear reference disagrees with its generated seed wheelbase.');
            end
        end
    end
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
