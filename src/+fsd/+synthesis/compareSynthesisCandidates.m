function comparison = compareSynthesisCandidates(result,indices)
%COMPARESYNTHESISCANDIDATES Same specification, full provenance and HP changes.
fsd.synthesis.validateSynthesisResult(result);
if nargin<2, indices=result.feasibleIndices; end
requireSynthesis(isnumeric(indices) && isreal(indices) && isvector(indices) && ~isempty(indices) && ...
    all(isfinite(indices)) && all(indices>=1 & indices<=numel(result.search.records) & fix(indices)==indices) && ...
    numel(unique(indices))==numel(indices),'Explicit unique evaluation indices required.');
records=result.search.records(indices); requireSynthesis(all(cellfun(@(e) ~isempty(e.candidate),records)),'Invalid geometry has no candidate to compare.');
candidates=cellfun(@(e) e.candidate,records,'UniformOutput',false);
comparison=fsd.analysis.compareDesignCandidates(result.problem.specification,candidates);
comparison.hardpointChanges=cellfun(@(e) e.changes,records,'UniformOutput',false);
comparison.synthesisClassifications=cellfun(@(e) e.classification,records);
end
