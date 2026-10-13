function valid = validateSteeringSynthesisEvaluation(evaluation,space)
%VALIDATESTEERINGSYNTHESISEVALUATION Rebuild axle, provenance, quality and assessment.
try
    fsd.synthesis.validateSteeringDesignSpace(space);
    axleEvaluationCore(space,evaluation.u,evaluation.evaluationId,evaluation);
catch cause
    exception=MException('fsd:synthesis:InvalidSteeringEvaluation','Steering evaluation contradicts its problem or native evidence.');
    throwAsCaller(addCause(exception,cause));
end
valid=true;
end
