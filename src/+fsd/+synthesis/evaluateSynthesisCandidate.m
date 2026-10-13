function evaluation = evaluateSynthesisCandidate(space,u,evaluationId)
%EVALUATESYNTHESISCANDIDATE Explicitly build and solve one normalized candidate.
if nargin<3, evaluationId = 1; end
fsd.synthesis.validateDesignSpace(space);
requireSynthesis(isnumeric(evaluationId) && isscalar(evaluationId) && isfinite(evaluationId) && ...
    evaluationId>=1 && fix(evaluationId)==evaluationId,'Positive integer evaluation ID required.');
evaluation = evaluateCore(space,u,evaluationId);
end
