function valid = validateDesignAssessment(assessment, specification, candidate)
%VALIDATEDESIGNASSESSMENT Reconstruct values, errors, coverage, identity and reporting.
expected = fsd.analysis.evaluateDesignCandidate(specification,candidate);
if ~isequaln(assessment,expected)
    error("fsd:analysis:InvalidDesignAssessment","Assessment is inconsistent with the original specification/candidate.");
end
valid = true;
end
