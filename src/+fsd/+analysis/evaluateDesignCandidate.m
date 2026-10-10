function assessment = evaluateDesignCandidate(specification, candidate)
%EVALUATEDESIGNCANDIDATE Evaluate explicit requirements on existing results, never solve.
fsd.model.validateDesignSpecification(specification);
sources = designPrepareCandidate(candidate);
assessment = designAssessmentCore(specification,candidate,sources);
end
