function valid = validateParametricSeedDefinition(definition)
%VALIDATEPARAMETRICSEEDDEFINITION Algebraic record reconstruction, no geometry solve.
seedRequire(isstruct(definition) && isscalar(definition) && ...
    isequaln(definition,seedDefinitionCore(definition.definitionSI)), 'Parametric definition cannot be reconstructed.');
valid=true;
end
