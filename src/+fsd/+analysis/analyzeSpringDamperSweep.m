function analysis = analyzeSpringDamperSweep(model, actuation, sweep, actuationAnalysis, wheelVelocity, velocityUnit)
%ANALYZESPRINGDAMPERSWEEP Quasistatic spring/damper response on a bump path.
% Uses achieved wheel travel, validated signed MR and actual damper lengths.
% Other independent coordinates are fixed by the source BumpSweepResult.
% wheelVelocity: scalar or N samples, defaults to zero m/s (prescribed rest).
if nargin < 5, wheelVelocity = 0; end
if nargin < 6, velocityUnit = "m/s"; end
source = struct("kind","ActuationSweep","sweep",sweep,"analysis",actuationAnalysis);
path = validateMechanicalSweepSource(model,source,actuation);
velocity = mechanicalVelocityInput(wheelVelocity,numel(path.converged),velocityUnit);
analysis = springDamperSweepCore(model,source,path,velocity);
verifyMechanicalPayload(analysis,model,path,velocity);
end
