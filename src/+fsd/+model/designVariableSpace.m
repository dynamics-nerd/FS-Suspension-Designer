function space = designVariableSpace(specification, requireClosed)
%DESIGNVARIABLESPACE Declare FREE/RANGE variables; never optimize or supply bounds.
if nargin < 2, requireClosed = false; end
fsd.model.validateDesignSpecification(specification);
if ~islogical(requireClosed) || ~isscalar(requireClosed)
    error("fsd:model:InvalidDesignDefinition","requireClosed must be scalar logical.");
end
variables = cell(0,1); missing = strings(0,1);
parameters = specification.definitionSI.parameters;
for i = 1:numel(parameters)
    p = parameters{i}.definitionSI;
    if ~any(p.type == ["FREE","RANGE"]), continue; end
    variables{end+1,1} = p; %#ok<AGROW>
    if isempty(p.bounds) || p.binding == "NONE"
        missing(end+1,1) = p.id; %#ok<AGROW>
    end
end
status = "CLOSED_DECLARED_SPACE";
if ~isempty(missing), status = "INCOMPLETE_VARIABLE_SPACE"; end
if requireClosed && ~isempty(missing)
    error("fsd:model:IncompleteDesignSpace","Explicit finite bounds and bindings required; missing %s.",join(missing,","));
end
space = struct("specificationIdentity",specification.identity,"variables",{variables}, ...
    "status",status,"missingBoundsOrBindings",missing,"optimizerImplemented",false);
end
