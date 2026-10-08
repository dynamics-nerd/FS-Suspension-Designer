function isValid = validateSpringDamperStateAnalysis(analysis, model)
%VALIDATESPRINGDAMPERSTATEANALYSIS Check source and all axial-only outputs.
if ~isstruct(analysis) || ~isscalar(analysis) || ...
        ~all(isfield(analysis,["source","inputDamperVelocity_m_per_s"]))
    error("fsd:analysis:InvalidSpringDamperAnalysis","Incomplete state analysis.");
end
fsd.model.validateSpringDamperModel(model);
fsd.kinematics.validateActuationResult(analysis.source);
if ~isequal(model.actuationIdentity,analysis.source.actuationIdentity)
    error("fsd:analysis:SpringDamperIdentityMismatch","Model belongs to another actuation.");
end
mechanicalVelocityInput(analysis.inputDamperVelocity_m_per_s,1,"m/s");
verifyMechanicalStatePayload(analysis,model);
isValid = true;
end
