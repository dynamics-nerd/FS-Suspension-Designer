function spec = designSpecificationCore(input)
%DESIGNSPECIFICATIONCORE Parameters, constraints and targets remain separate.
emptyTargets = fsd.model.createSuspensionDesignTargets(cell(0,1));
d = designDefinition(input,struct("id",[],"parameters",{{}},"constraints",{{}}, ...
    "targets",emptyTargets,"compositeScore",false,"metadata",struct()),"id");
d.id = designText(d.id);
for field = ["parameters","constraints"]
    cells = d.(field); designRequire(iscell(cells) && (isempty(cells) || isvector(cells)),"Expected cell vector.");
    ids = strings(numel(cells),1);
    for i = 1:numel(cells)
        if field == "parameters", fsd.model.validateDesignParameter(cells{i});
        else, fsd.model.validateDesignConstraint(cells{i}); end
        ids(i) = cells{i}.definitionSI.id;
    end
    designRequire(numel(unique(ids)) == numel(ids),"Duplicate parameter/constraint IDs.");
    d.(field) = cells(:);
end
fsd.model.validateSuspensionDesignTargets(d.targets);
allIds = cellfun(@(v) v.definitionSI.id,[d.parameters;d.constraints;d.targets.definitionSI.targets]);
designRequire(numel(unique(allIds)) == numel(allIds),"Requirement IDs must be unique across the specification.");
designRequire(islogical(d.compositeScore) && isscalar(d.compositeScore),"Composite score option must be logical.");
if d.compositeScore
    soft = 0;
    for i = 1:numel(d.targets.definitionSI.targets)
        t = d.targets.definitionSI.targets{i}.definitionSI;
        if t.strength == "SOFT"
            soft = soft+1;
            designRequire(~isempty(t.weight) && ~isempty(t.normalizationScale),"Score requires every soft weight and normalization.");
        end
    end
    designRequire(soft > 0,"Score requires at least one soft objective.");
end
spec = designRecord("DesignSpecification",d);
for field = ["parameters","constraints"]
    spec.identity.definitionSI.(field) = cellfun(@(v) v.identity,d.(field),"UniformOutput",false);
end
spec.identity.definitionSI.targets = d.targets.identity;
end
