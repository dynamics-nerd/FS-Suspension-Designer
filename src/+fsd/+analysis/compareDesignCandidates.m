function comparison = compareDesignCandidates(specification, candidates)
%COMPAREDESIGNCANDIDATES Same specification, individual errors; no automatic winner.
if ~iscell(candidates) || numel(candidates) < 2
    error("fsd:analysis:InvalidDesignCandidate","At least two candidate structs in a cell vector required.");
end
candidates = candidates(:); assessments = cell(size(candidates)); ids = strings(size(candidates));
for i = 1:numel(candidates)
    assessments{i} = fsd.analysis.evaluateDesignCandidate(specification,candidates{i});
    ids(i) = candidates{i}.definitionSI.id;
end
if numel(unique(ids)) ~= numel(ids)
    error("fsd:analysis:InvalidDesignCandidate","Comparison requires distinct candidate IDs.");
end
comparison = struct("schemaVersion","0.11.0","kind","DesignComparison", ...
    "specificationIdentity",specification.identity,"candidateIds",ids, ...
    "assessments",{assessments},"selectionPolicy","NO_AUTOMATIC_WINNER");
end
