function valid = validateSynthesisResult(result)
%VALIDATESYNTHESISRESULT Reconstruct records and replay controller without physical solves.
try
    space=result.problem; fsd.synthesis.validateDesignSpace(space); search=result.search;
    requireSynthesis(isequaln(result.execution,executionSnapshot(space)),'Execution plan provenance mismatch.');
    for i=1:numel(search.records)
        fsd.synthesis.validateSynthesisEvaluation(search.records{i},space);
        requireSynthesis(search.records{i}.evaluationId==i,'Evaluation order mismatch.');
    end
    initial=coordinateCore(space,space.initial_m,"NORMALIZE");
    expected=fsd.synthesis.boundedDirectSearch(initial,space.active,search.options, ...
        @replay,@(u) coordinateCore(space,u,"DENORMALIZE"));
    requireSynthesis(isequaln(search,expected),'History/selection/stop/cache does not match deterministic replay.');
    requireSynthesis(result.kind=="SynthesisResult" && result.schemaVersion=="0.12.0" && ...
        isequaln(result.feasibleIndices,search.eligibleIndices) && isequaln(result.selectedIndex,search.selectedIndex) && ...
        result.selectionPolicy=="BEST_EXPLICIT_SCORE_AMONG_EXPLORED_ELIGIBLE_ONLY",'Result summary mismatch.');
    diagnostics=strings(0,1);
    if isempty(search.eligibleIndices), diagnostics(end+1,1)="NO_FULLY_EVALUATED_SAMPLED_FEASIBLE_CANDIDATE"; end
    if isnan(search.selectedIndex), diagnostics(end+1,1)="NO_AUTOMATIC_WINNER_WITHOUT_COMPLETE_EXPLICIT_SCORE"; end
    requireSynthesis(isequaln(result.diagnostics,diagnostics) && isnumeric(result.elapsedTime_s) && ...
        isscalar(result.elapsedTime_s) && isfinite(result.elapsedTime_s) && result.elapsedTime_s>=0,'Diagnostics mismatch.');
    requireSynthesis(isequaln(result.statistics,resultStatistics(search,result.elapsedTime_s)) && ...
        result.statistics.controllerOverhead_s>=0,'Statistics mismatch.');
catch cause
    exception=MException('fsd:synthesis:InvalidResult','Synthesis result is inconsistent with the declared problem/native evidence.');
    throwAsCaller(addCause(exception,cause));
end
valid=true;
    function record = replay(u,id)
        record=search.records{id};
        requireSynthesis(isequaln(record.u,u),'New evaluation vector/order mismatch.');
    end
end
