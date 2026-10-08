function analysis = analyzeSpringDamperState(model, result, damperVelocity, velocityUnit)
%ANALYZESPRINGDAMPERSTATE Axial-only response from a single ActuationResult.
% damperVelocity is prescribed axial COMPRESSION velocity, NOT wheel velocity.
% Defaults to prescribed rest. No validated MR: all wheel metrics remain NaN.
if nargin < 3, damperVelocity = 0; end
if nargin < 4, velocityUnit = "m/s"; end
fsd.model.validateSpringDamperModel(model);
fsd.kinematics.validateActuationResult(result);
if ~isequal(model.actuationIdentity,result.actuationIdentity)
    error("fsd:analysis:SpringDamperIdentityMismatch","Model belongs to another actuation.");
end
velocity = mechanicalVelocityInput(damperVelocity,1,velocityUnit);
analysis = springDamperSingleCore(model,result,velocity);
verifyMechanicalStatePayload(analysis,model);
end
