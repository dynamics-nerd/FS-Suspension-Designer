function targets = designTargetsCore(input)
%DESIGNTARGETSCORE Standalone target specification, no hardpoint prerequisite.
d = designDefinition(input,struct("targets",{{}},"metadata",struct()),"targets");
designRequire(iscell(d.targets) && (isempty(d.targets) || isvector(d.targets)),"Targets must be a cell vector.");
d.targets = d.targets(:); ids = strings(numel(d.targets),1);
for i = 1:numel(d.targets)
    fsd.model.validateDesignTarget(d.targets{i}); ids(i) = d.targets{i}.definitionSI.id;
end
designRequire(numel(unique(ids)) == numel(ids),"Duplicate target IDs.");
targets = designRecord("SuspensionDesignTargets",d);
% Nested display metadata is not physical identity.
targets.identity.definitionSI.targets = cellfun(@(t) t.identity,d.targets,"UniformOutput",false);
end
