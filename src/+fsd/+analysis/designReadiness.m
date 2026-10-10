function readiness = designReadiness(specification, candidate)
%DESIGNREADINESS Missing sources/quality/references and incomplete variable bounds.
assessment = fsd.analysis.evaluateDesignCandidate(specification,candidate);
readiness = assessment.readiness;
end
