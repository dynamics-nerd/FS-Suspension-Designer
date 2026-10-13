function valid = validateSteeringSynthesisResult(result)
%VALIDATESTEERINGSYNTHESISRESULT Native evidence plus exact controller replay; no solve.
try
    space=result.problem; fsd.synthesis.validateSteeringDesignSpace(space); search=result.search;
    requireSynthesis(isequaln(result.execution,axleExecutionSnapshot(space)),'Joint execution snapshot mismatch.');
    for i=1:numel(search.records)
        fsd.synthesis.validateSteeringSynthesisEvaluation(search.records{i},space);
        requireSynthesis(search.records{i}.evaluationId==i,'Evaluation order mismatch.');
    end
    initial=coordinateCore(space,space.initial_m,"NORMALIZE");
    expected=fsd.synthesis.boundedDirectSearch(initial,space.active,search.options,@replay, ...
        @(u) coordinateCore(space,u,"DENORMALIZE"));
    requireSynthesis(isequaln(search,expected),'Search/history/cache/selection replay mismatch.');
    requireSynthesis(result.schemaVersion=="0.14.0" && result.kind=="SteeringSynthesisResult" && ...
        isequaln(result.feasibleIndices,search.eligibleIndices) && isequaln(result.selectedIndex,search.selectedIndex) && ...
        result.selectionPolicy=="BEST_EXPLICIT_SCORE_AMONG_EXPLORED_ELIGIBLE_ONLY" && ...
        isequaln(result.diagnostics,axleResultDiagnostics(search)),'Result summary mismatch.');
    requireSynthesis(isnumeric(result.elapsedTime_s) && isreal(result.elapsedTime_s) && isscalar(result.elapsedTime_s) && ...
        isfinite(result.elapsedTime_s) && result.elapsedTime_s>=0,'Invalid result timing.');
    requireSynthesis(isequaln(result.statistics,axleResultStatistics(search,result.elapsedTime_s)) && ...
        result.statistics.controllerOverhead_s>=0,'Physical accounting mismatch.');
catch cause
    exception=MException('fsd:synthesis:InvalidSteeringResult','Steering result contradicts its problem, evidence or controller.');
    throwAsCaller(addCause(exception,cause));
end
valid=true;
    function record = replay(u,id)
        requireSynthesis(id<=numel(search.records),'Replay requested an unrecorded evaluation.');
        record=search.records{id}; requireSynthesis(isequaln(record.u,u),'Replay vector/order mismatch.');
    end
end
