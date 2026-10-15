function result = buildParametricSeed(definition,referenceParameters)
%BUILDPARAMETRICSEED Deterministic native geometry; physical sampling is separate.
fsd.construction.validateParametricSeedDefinition(definition);
result=seedBuildCore(definition,referenceParameters);
end
