function evaluation = classifyEvaluation(evaluation)
%CLASSIFYEVALUATION Keep quality, HARD and scalar preference separate.
evaluation.eligible = false; evaluation.score = NaN;
if ~evaluation.geometryValid
    evaluation.classification = "INVALID_GEOMETRY"; evaluation.reason=evaluation.classification; return;
end
if isempty(evaluation.candidate)
    evaluation.classification = "SOLVER_FAILED";
    if evaluation.failureStage=="ANALYSIS", evaluation.classification="ANALYSIS_FAILED"; end
    evaluation.reason=evaluation.classification; return;
end
a = evaluation.assessment; quality = evaluation.quality;
evaluation.hardFeasibility = a.hardFeasibility;
if a.hardFeasibility == "INFEASIBLE_FOR_SPECIFICATION"
    evaluation.classification = "HARD_CONSTRAINT_FAILED";
elseif ~isempty(quality) && ~any(evaluation.candidate.definitionSI.sources{1}.sweep.converged)
    evaluation.classification = "SOLVER_FAILED";
elseif ~isempty(quality) && ~quality.allReliable
    evaluation.classification = "INDETERMINATE";
elseif a.hardFeasibility == "INDETERMINATE_HARD_REQUIREMENTS"
    evaluation.classification = "INDETERMINATE";
elseif ~a.readiness.allRequirementsEvaluated
    evaluation.classification = "NOT_EVALUABLE";
else
    evaluation.classification = "SAMPLED_FEASIBLE";
    evaluation.eligible = true; evaluation.score = a.compositeScore;
end
evaluation.reason = evaluation.classification;
end
