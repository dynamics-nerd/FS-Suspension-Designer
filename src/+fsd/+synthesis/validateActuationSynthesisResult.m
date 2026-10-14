function valid = validateActuationSynthesisResult(result)
%VALIDATEACTUATIONSYNTHESISRESULT Rebuild records and replay search without physical solves.
try
    space=result.problem; fsd.synthesis.validateActuationDesignSpace(space); search=result.search;
    requireSynthesis(isequaln(result.execution,actuationExecutionSnapshot(space)), 'Result context mismatch.');
    for j=1:numel(search.records)
        fsd.synthesis.validateActuationSynthesisEvaluation(search.records{j},space);
        requireSynthesis(search.records{j}.evaluationId==j,'Evaluation order mismatch.');
    end
    initial=coordinateCore(space,space.initial_m,"NORMALIZE");
    expected=fsd.synthesis.boundedDirectSearch(initial,space.active,search.options,@replay, ...
        @(u) coordinateCore(space,u,"DENORMALIZE"));
    requireSynthesis(isequaln(search,expected),'Search history/cache/stop/selection mismatch.');
    requireSynthesis(result.kind=="ActuationSynthesisResult" && result.schemaVersion=="0.15.0" && ...
        isequaln(result.feasibleIndices,search.eligibleIndices) && isequaln(result.selectedIndex,search.selectedIndex) && ...
        result.selectionPolicy=="BEST_EXPLICIT_SCORE_AMONG_EXPLORED_ELIGIBLE_ONLY",'Invalid result summary.');
    requireSynthesis(isnumeric(result.elapsedTime_s) && isscalar(result.elapsedTime_s) && ...
        isreal(result.elapsedTime_s) && isfinite(result.elapsedTime_s) && result.elapsedTime_s>=0 && ...
        isequaln(result.diagnostics,axleResultDiagnostics(search)), 'Invalid result timing/diagnostics.');
    requireSynthesis(isequaln(result.statistics,actuationResultStatistics(search,result.elapsedTime_s)) && ...
        result.statistics.controllerOverhead_s>=0,'Invalid result counters.');
catch cause
    exception=MException('fsd:synthesis:InvalidActuationResult','Actuation synthesis result is inconsistent.');
    throwAsCaller(addCause(exception,cause));
end
valid=true;
    function record = replay(u,id)
        record=search.records{id}; requireSynthesis(isequaln(record.u,u),'Replay vector/order mismatch.');
    end
end
