function steering = createSeedSteering(seed)
%CREATESEEDSTEERING Explicit minimal native steering association, never automatic.
fsd.construction.validateParametricSeedResult(seed);
projectRequire(seed.nominalStatus=="VALID" && ~isempty(seed.axle) && seed.axle.axleId=="FRONT", ...
    'A valid generated FRONT pair and explicit tie endpoints are required.');
refs=seed.referenceParameters; i=find(cellfun(@(p)p.definitionSI.id=="WHEELBASE",refs));
projectRequire(isscalar(i),'Physical wheelbase reference required.');
steering=fsd.model.createSteeringSystem(seed.axle,refs{i}.definitionSI.value,'m');
end
