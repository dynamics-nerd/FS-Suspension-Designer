function valid=validateDefinition(definition)
%VALIDATEDEFINITION Reconstruct physical declarations, pair authority and regions.
assert(isstruct(definition) && isscalar(definition) && isfield(definition,'definitionSI'), ...
    'fsd:packaging:InvalidDefinition','PackagingDefinition required.');
assert(isequaln(definition,fsd.packaging.createDefinition(definition.definitionSI)), ...
    'fsd:packaging:InvalidDefinition','Definition differs from its canonical record.');
valid=true;
end
