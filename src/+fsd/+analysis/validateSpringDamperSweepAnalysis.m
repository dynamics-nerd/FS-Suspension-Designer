function isValid = validateSpringDamperSweepAnalysis(analysis, model, actuation)
%VALIDATESPRINGDAMPERSWEEPANALYSIS Reconstruct laws, statuses and source linkage.
% Actuation geometry required for a production sweep; omitted for prescribed path.
if nargin < 3, actuation = []; end
if ~isstruct(analysis) || ~isscalar(analysis) || ...
        ~all(isfield(analysis,["source","path","inputWheelVelocity_m_per_s"]))
    error("fsd:analysis:InvalidSpringDamperAnalysis","Incomplete mechanical analysis.");
end
path = validateMechanicalSweepSource(model,analysis.source,actuation);
velocity = mechanicalVelocityInput(analysis.inputWheelVelocity_m_per_s, ...
    numel(path.converged),"m/s");
if ~isequaln(analysis.path,path) || ...
        ~isequal(analysis.inputWheelVelocity_m_per_s,velocity)
    error("fsd:analysis:InvalidSpringDamperAnalysis","Source path or velocity correspondence changed.");
end
verifyMechanicalPayload(analysis,model,path,velocity);
isValid = true;
end
