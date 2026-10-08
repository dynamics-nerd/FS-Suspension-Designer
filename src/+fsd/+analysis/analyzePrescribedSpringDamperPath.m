function analysis = analyzePrescribedSpringDamperPath(model, wheelTravel, compression, wheelVelocity, units)
%ANALYZEPRESCRIBEDSPRINGDAMPERPATH Explicit ideal 1-D c(z), NOT rocker kinematics.
% Intended for independent benchmarks or a separately documented prescribed
% path. Fixed other coordinates are assumed. No ActuationResult is fabricated.
% units.length and units.velocity are required. Velocities scalar or N-vector.
validateattributes(wheelTravel,{'numeric'},{'real','finite','vector','nonempty'});
validateattributes(compression,{'numeric'},{'real','finite','vector','nonempty'});
if ~isstruct(units) || ~isscalar(units) || ...
        ~all(isfield(units,["length","velocity"]))
    error("fsd:analysis:InvalidSpringDamperAnalysis","Explicit path units required.");
end
source = struct("kind","PrescribedDamperPath", ...
    "wheelTravel_m",fsd.model.convertMechanicalUnits(wheelTravel(:),"length",units.length,"m"), ...
    "damperCompression_m",fsd.model.convertMechanicalUnits(compression(:),"length",units.length,"m"));
path = validateMechanicalSweepSource(model,source,[]);
velocity = mechanicalVelocityInput(wheelVelocity,numel(path.converged),units.velocity);
analysis = springDamperSweepCore(model,source,path,velocity);
verifyMechanicalPayload(analysis,model,path,velocity);
end
