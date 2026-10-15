function quality = bumpSweepQuality(geometry,sweep)
%BUMPSWEEPQUALITY Public reuse of the existing local closure/branch guard.
fsd.model.validateDoubleWishboneGeometry(geometry);
fsd.kinematics.validateBumpSweepResult(sweep);
requireSynthesis(isequaln(sweep.geometryIdentity,fsd.model.geometryIdentity(geometry)), 'BUMP geometry association differs.');
quality=bumpQuality(geometry,sweep);
end
