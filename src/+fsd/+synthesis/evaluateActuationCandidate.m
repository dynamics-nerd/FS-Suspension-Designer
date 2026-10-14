function evaluation = evaluateActuationCandidate(space,u,evaluationId)
%EVALUATEACTUATIONCANDIDATE Fresh native BUMP and actuation, optional mechanics.
if nargin<3, evaluationId=1; end
fsd.synthesis.validateActuationDesignSpace(space);
evaluation=actuationEvaluationCore(space,u,evaluationId);
end
