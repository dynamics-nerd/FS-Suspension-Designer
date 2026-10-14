function stats = actuationResultStatistics(search,elapsed)
%ACTUATIONRESULTSTATISTICS Native physical sweeps distinct from algebraic analyses.
bump=0; actuation=0; mechanical=0; closures=0; builders=0; nominal=0; phase=0;
for j=1:numel(search.records)
    e=search.records{j}; builders=builders+double(~e.geometryValid); phase=phase+e.timing_s.total;
    nominal=nominal+double(e.evidenceStatus=="NOMINAL_HARD_REJECTED");
    if ~isempty(e.bumpEvidence), bump=bump+e.bumpEvidence.solverCalls; end
    if ~isempty(e.actuationEvidence)
        actuation=actuation+e.actuationEvidence.solverCalls;
        closures=closures+e.actuationEvidence.sweep.performance.rockerClosureSolveCount;
    end
    if ~isempty(e.mechanicalEvidence), mechanical=mechanical+e.mechanicalEvidence.analysisCalls; end
end
stats=struct('candidateEvaluations',search.evaluationCount,'attempts',search.attemptCount, ...
    'cacheHits',search.cacheHitCount,'builderFailures',builders,'nominalHardRejections',nominal, ...
    'preSolverFailures',builders+nominal,'bumpSweeps',bump,'actuationSweeps',actuation, ...
    'physicalSweepInvocations',bump+actuation,'nativeRockerClosures',closures, ...
    'mechanicalAnalyses',mechanical,'eligibleCandidates',numel(search.eligibleIndices), ...
    'candidateTime_s',phase,'controllerOverhead_s',elapsed-phase);
end
