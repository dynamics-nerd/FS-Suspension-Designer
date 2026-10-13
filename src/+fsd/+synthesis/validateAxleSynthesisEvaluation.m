function valid = validateAxleSynthesisEvaluation(evaluation,space)
%VALIDATEAXLESYNTHESISEVALUATION Rebuild axle, provenance, quality and assessment.
try
    fsd.synthesis.validateAxleDesignSpace(space);
    axleEvaluationCore(space,evaluation.u,evaluation.evaluationId,evaluation);
catch cause
    exception=MException('fsd:synthesis:InvalidAxleEvaluation','Axle evaluation contradicts its problem or native evidence.');
    throwAsCaller(addCause(exception,cause));
end
valid=true;
end
