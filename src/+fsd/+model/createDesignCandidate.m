function candidate = createDesignCandidate(definition)
%CREATEDESIGNCANDIDATE Associate models and existing results, not another solve.
% Model validation is structural; analysis.validateDesignCandidate verifies sources.
candidate = designCandidateCore(definition);
end
