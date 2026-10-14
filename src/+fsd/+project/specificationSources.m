function sources = specificationSources(specification)
%SPECIFICATIONSOURCES Inspect the authoritative v0.11 metric/source catalogue.
fsd.model.validateDesignSpecification(specification);
catalog=fsd.model.designMetricCatalog(); targets=specification.definitionSI.targets.definitionSI.targets;
sources=cell(numel(targets),1);
for j=1:numel(targets)
    t=targets{j}.definitionSI; row=find(string({catalog.id})==t.metricId);
    projectRequire(isscalar(row) && ismember(t.sourceType,catalog(row).sourceTypes),'Unsupported metric/source.');
    sources{j}=struct('targetId',t.id,'sourceId',t.sourceId,'sourceType',t.sourceType, ...
        'metricId',t.metricId,'scope',t.scope,'independentVariable',t.independentVariable, ...
        'unit',catalog(row).unit,'strength',t.strength,'conditions',t.conditions, ...
        'requiredSourceIdentity',t.requiredSourceIdentity, ...
        'prerequisites',catalog(row).prerequisites);
end
end
