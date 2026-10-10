function target = createDesignTarget(definition, inputUnit, coordinateUnit)
%CREATEDESIGNTARGET Scalar/band/curve objective with explicit SI conversion.
designRequire(isstruct(definition) && isscalar(definition) && ...
    all(isfield(definition,["metricId","independentVariable"])),"Target definition/coordinate required.");
catalog = fsd.model.designMetricCatalog;
j = find(string({catalog.id}) == designText(definition.metricId));
designRequire(isscalar(j),"Unknown metric.");
for field = ["value","tolerance","lower","upper","normalizationScale","numericalTolerance","physicalUncertainty"]
    if isfield(definition,field)
        definition.(field) = fsd.model.convertDesignUnits(definition.(field),catalog(j).quantity,inputUnit);
    end
end
definition.unit = catalog(j).unit;
quantity = "LENGTH";
if string(definition.independentVariable) == "ROLL_ANGLE", quantity = "ANGLE";
elseif string(definition.independentVariable) == "NONE", quantity = "RATIO";
end
if ~isfield(definition,"x"), definition.x = []; end
[definition.x,definition.xUnit] = fsd.model.convertDesignUnits(definition.x,quantity,coordinateUnit);
target = designTargetCore(definition);
end
