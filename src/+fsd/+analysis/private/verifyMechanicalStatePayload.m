function verifyMechanicalStatePayload(analysis,model)
%VERIFYMECHANICALSTATEPAYLOAD Reconstruct without repeating source validation.
expected = springDamperSingleCore(model,analysis.source,analysis.inputDamperVelocity_m_per_s);
if ~isequaln(analysis,expected)
    error("fsd:analysis:InvalidSpringDamperAnalysis","Inconsistent axial mechanical response.");
end
end
