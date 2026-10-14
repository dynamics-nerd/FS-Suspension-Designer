function comparison = compareActuationSynthesisCandidates(result,indices)
%COMPAREACTUATIONSYNTHESISCANDIDATES Same complete specification, existing evidence only.
fsd.synthesis.validateActuationSynthesisResult(result);
requireSynthesis(isnumeric(indices) && isreal(indices) && isvector(indices) && numel(indices)>=2 && ...
    all(isfinite(indices)) && all(indices==fix(indices)) && numel(unique(indices))==numel(indices) && ...
    all(indices>=1 & indices<=numel(result.search.records)),'At least two distinct valid evaluation indices required.');
records=result.search.records(indices); candidates=cellfun(@(e)e.candidate,records,'UniformOutput',false);
requireSynthesis(all(~cellfun(@isempty,candidates)),'Builder failures have no design candidate.');
comparison=fsd.analysis.compareDesignCandidates(result.problem.specification,candidates);
comparison.evaluationIndices=indices(:); comparison.changes=cellfun(@(e)e.changes,records,'UniformOutput',false);
comparison.classifications=cellfun(@(e)e.classification,records);
end
