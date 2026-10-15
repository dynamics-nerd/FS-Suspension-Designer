function ids = seedReferenceIds(definition)
%SEEDREFERENCEIDS Only dimensions consumed by this family, never mass or CG.
fsd.construction.validateParametricSeedDefinition(definition);
track="FRONT_TRACK"; if ismember(definition.definitionSI.cornerId,["RL","RR"]), track="REAR_TRACK"; end
ids=["WHEELBASE";track];
end
