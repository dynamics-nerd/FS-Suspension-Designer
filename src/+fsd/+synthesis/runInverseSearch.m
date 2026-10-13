function result = runInverseSearch(space,options)
%RUNINVERSESEARCH Explicit physical orchestration with bounded deterministic search.
if nargin<2, options=struct(); end
fsd.synthesis.validateDesignSpace(space);
if ~isempty(space.sourceIds) && (exist('fsolve','file')~=2 || ~license('test','Optimization_Toolbox'))
    error('fsd:synthesis:MissingKinematicDependency','Historical BUMP solver requires fsolve. Search itself uses base MATLAB only.');
end
timer = tic; execution=executionSnapshot(space); initial=coordinateCore(space,space.initial_m,"NORMALIZE");
search=fsd.synthesis.boundedDirectSearch(initial,space.active,options, ...
    @(u,id) evaluateCore(space,u,id),@(u) coordinateCore(space,u,"DENORMALIZE"));
result=struct('schemaVersion',"0.12.0",'kind',"SynthesisResult",'problem',space,'execution',execution, ...
    'search',search,'feasibleIndices',search.eligibleIndices,'selectedIndex',search.selectedIndex, ...
    'selectionPolicy',"BEST_EXPLICIT_SCORE_AMONG_EXPLORED_ELIGIBLE_ONLY", ...
    'elapsedTime_s',toc(timer),'diagnostics',strings(0,1));
result.statistics=resultStatistics(search,result.elapsedTime_s);
if isempty(result.feasibleIndices)
    result.diagnostics(end+1,1)="NO_FULLY_EVALUATED_SAMPLED_FEASIBLE_CANDIDATE";
end
if isnan(result.selectedIndex)
    result.diagnostics(end+1,1)="NO_AUTOMATIC_WINNER_WITHOUT_COMPLETE_EXPLICIT_SCORE";
end
end
