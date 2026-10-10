function parameter = createDesignParameter(definition, inputUnit)
%CREATEDESIGNPARAMETER Preliminary scalar data/design variable, without geometry.
designRequire(isstruct(definition) && isscalar(definition) && isfield(definition,"quantity"),"Parameter definition/quantity required.");
fields = ["value","bounds","comparisonTolerance"];
for field = fields
    if isfield(definition,field)
        definition.(field) = fsd.model.convertDesignUnits(definition.(field),definition.quantity,inputUnit);
    end
end
[~,definition.unit] = fsd.model.convertDesignUnits([],definition.quantity,inputUnit);
parameter = designParameterCore(definition);
end
