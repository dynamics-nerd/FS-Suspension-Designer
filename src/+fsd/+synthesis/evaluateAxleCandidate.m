function evaluation = evaluateAxleCandidate(space,u,evaluationId)
%EVALUATEAXLECANDIDATE Explicit fresh bilateral BUMP and optional native ROLL.
if nargin<3, evaluationId=1; end
fsd.synthesis.validateAxleDesignSpace(space);
evaluation=axleEvaluationCore(space,u,evaluationId);
end
