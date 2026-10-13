function evaluation = evaluateSteeringCandidate(space,u,evaluationId)
%EVALUATESTEERINGCANDIDATE Fresh bilateral BUMP/RACK, with optional native ROLL.
if nargin<3, evaluationId=1; end
fsd.synthesis.validateSteeringDesignSpace(space);
evaluation=axleEvaluationCore(space,u,evaluationId);
end
