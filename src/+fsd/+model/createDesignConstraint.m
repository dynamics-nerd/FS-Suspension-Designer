function constraint = createDesignConstraint(definition, inputUnit)
%CREATEDESIGNCONSTRAINT Admissible nominal hardpoint region, not collision detection.
for field = ["position","bounds","comparisonTolerance"]
    if isfield(definition,field)
        definition.(field) = fsd.model.convertLengthToMetres(definition.(field),inputUnit);
    end
end
definition.unit = "m";
constraint = designConstraintCore(definition);
end
