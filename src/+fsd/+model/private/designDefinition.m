function d = designDefinition(input, template, required)
%DESIGNDEFINITION Closed field set; display-only metadata is stored separately.
designRequire(isstruct(input) && isscalar(input) && all(isfield(input,required)) && ...
    isempty(setdiff(fieldnames(input),fieldnames(template))),"Incomplete/unknown definition fields.");
d = template; names = fieldnames(input);
for i = 1:numel(names), d.(names{i}) = input.(names{i}); end
end
