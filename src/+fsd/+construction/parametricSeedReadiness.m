function report = parametricSeedReadiness(definition,referenceParameters)
%PARAMETRICSEEDREADINESS Input eligibility only; no construction or forward solve.
fsd.construction.validateParametricSeedDefinition(definition);
report=seedInputCore(definition,referenceParameters);
end
