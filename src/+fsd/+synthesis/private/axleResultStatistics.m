function stats = axleResultStatistics(search,elapsed)
%AXLERESULTSTATISTICS Candidate budget is distinct from physical invocations.
calls=zeros(1,numel(search.records{1}.physical)); nativeRollCornerSolves=0; builderFailures=0; phase=0;
for i=1:numel(search.records)
    e=search.records{i}; builderFailures=builderFailures+double(~e.geometryValid);
    phase=phase+e.timing_s.total;
    for j=1:numel(e.physical)
        p=e.physical{j}; if isempty(p), continue; end
        calls(j)=calls(j)+p.solverCalls;
        if j==3 && ~isempty(p.sweep), nativeRollCornerSolves=nativeRollCornerSolves+p.sweep.performance.cornerSolves; end
    end
end
stats=struct('axleCandidateEvaluations',search.evaluationCount,'attempts',search.attemptCount, ...
    'cacheHits',search.cacheHitCount,'leftBumpSweeps',calls(1),'rightBumpSweeps',calls(2), ...
    'rollSweeps',calls(3),'totalPhysicalSweepInvocations',sum(calls), ...
    'nativeRollCornerSolves',nativeRollCornerSolves,'preSolverFailures',builderFailures, ...
    'eligibleCandidates',numel(search.eligibleIndices),'candidateTime_s',phase,'controllerOverhead_s',elapsed-phase);
if numel(calls)==4, stats.rackSweeps=calls(4); end
end
