function comparison = compareAxleSynthesisCandidates(result,indices)
%COMPAREAXLESYNTHESISCANDIDATES Joint v0.11 comparison, never a second optimizer.
fsd.synthesis.validateAxleSynthesisResult(result);
requireSynthesis(isnumeric(indices) && isreal(indices) && isvector(indices) && numel(indices)>=2 && ...
    all(isfinite(indices) & indices>=1 & indices<=numel(result.search.records) & indices==fix(indices)) && ...
    numel(unique(indices))==numel(indices),'At least two distinct recorded indices required.');
records=result.search.records(indices);
requireSynthesis(all(cellfun(@(e) ~isempty(e.candidate),records)),'Rejected builder has no candidate to compare.');
candidates=cellfun(@(e) e.candidate,records,'UniformOutput',false);
comparison=fsd.analysis.compareDesignCandidates(result.problem.specification,candidates);
comparison.evaluationIndices=indices(:);
comparison.hardpointChanges=cellfun(@(e) e.changes,records,'UniformOutput',false);
comparison.synthesisClassifications=cellfun(@(e) e.classification,records);
end
