function verifyMechanicalPayload(analysis, model, path, velocity)
%VERIFYMECHANICALPAYLOAD Cheap reconstruction without upstream validation/solves.
if ~isfield(analysis,"elapsedTime_s") || ~isnumeric(analysis.elapsedTime_s) || ...
        ~isscalar(analysis.elapsedTime_s) || ~isfinite(analysis.elapsedTime_s) || ...
        analysis.elapsedTime_s < 0
    error("fsd:analysis:InvalidSpringDamperAnalysis","Invalid timing diagnostic.");
end
expected = springDamperSweepCore(model,analysis.source,path,velocity);
if ~isequaln(rmfield(analysis,"elapsedTime_s"),rmfield(expected,"elapsedTime_s"))
    error("fsd:analysis:InvalidSpringDamperAnalysis","Inconsistent mechanical payload or identity.");
end
end
