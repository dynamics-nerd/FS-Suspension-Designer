function valid = validateActuationSynthesisEvaluation(evaluation,space)
%VALIDATEACTUATIONSYNTHESISEVALUATION Native evidence replay without physical solves.
try
    fsd.synthesis.validateActuationDesignSpace(space);
    actuationEvaluationCore(space,evaluation.u,evaluation.evaluationId,evaluation);
catch cause
    exception=MException('fsd:synthesis:InvalidActuationEvaluation','Actuation evaluation contradicts its problem or evidence.');
    throwAsCaller(addCause(exception,cause));
end
valid=true;
end
