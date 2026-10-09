function prepared = prepareGlobalStaticSystem(system)
%PREPAREGLOBALSTATICSYSTEM Validate sources once, build segmented C1 interpolants.
t = tic;
fsd.model.validateGlobalStaticSystem(system);
paths = cell(4,1); validationTime = toc(t); interpolationTime = 0;
nominal = zeros(4,3);
for i = 1:4
    t = tic; s = system.sources{i};
    fsd.analysis.validateSpringDamperSweepAnalysis(s.mechanical,s.springDamper,s.actuation);
    if any(s.mechanical.inputWheelVelocity_m_per_s ~= 0)
        error("fsd:analysis:InvalidGlobalStaticSystem","Static source must be at rest.");
    end
    [wc,branch] = globalWheelCenterSource(s);
    validationTime = validationTime+toc(t);
    t = tic; paths{i} = globalPathCore(s,wc,branch);
    interpolationTime = interpolationTime+toc(t);
    nominal(i,:) = fsd.model.getPoint(s.geometry,s.geometry.cornerId+"_WHEEL_CENTER");
end
M = system.vehicle.totalMass_kg; mu = system.unsprungMass_kg; Ms = M-sum(mu);
cg = (M*system.vehicle.cg_m-mu'*nominal)/Ms;
reference = fsd.analysis.analyzeStaticVehicleLoads(system.vehicle,system.loadCase);
reference = rmfield(reference,"elapsedTime_s"); % timing is not reconstructed physics
reference.loadCase = reference.loadCase.identity; % presentation metadata is not physics
prepared = struct("schemaVersion","0.10.0","kind","PreparedGlobalStaticSystem", ...
    "system",system,"identity",system.identity,"paths",{paths}, ...
    "sprungMass_kg",Ms,"sprungCgBody_m",cg,"nominalWheelCentersBody_m",nominal, ...
    "referenceLoadsV09",reference,"approximation","SAMPLED_PATH_APPROXIMATION", ...
    "performance",struct("sourceValidationTime_s",validationTime, ...
    "interpolationTime_s",interpolationTime,"sourceValidationPasses",1));
end
