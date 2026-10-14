function result = runActuationInverseSearch(space,options)
%RUNACTUATIONINVERSESEARCH Unchanged v0.12 controller over native actuation physics.
if nargin<2, options=struct(); end
fsd.synthesis.validateActuationDesignSpace(space);
if exist('fsolve','file')~=2 || ~license('test','Optimization_Toolbox')
    error('fsd:synthesis:MissingKinematicDependency','Native BUMP requires Optimization Toolbox/fsolve.');
end
execution=actuationExecutionSnapshot(space); timer=tic;
initial=coordinateCore(space,space.initial_m,"NORMALIZE");
search=fsd.synthesis.boundedDirectSearch(initial,space.active,options, ...
    @(u,id) actuationEvaluationCore(space,u,id),@(u) coordinateCore(space,u,"DENORMALIZE"));
result=struct('schemaVersion',"0.15.0",'kind',"ActuationSynthesisResult",'problem',space,'execution',execution, ...
    'search',search,'feasibleIndices',search.eligibleIndices,'selectedIndex',search.selectedIndex, ...
    'selectionPolicy',"BEST_EXPLICIT_SCORE_AMONG_EXPLORED_ELIGIBLE_ONLY",'elapsedTime_s',toc(timer), ...
    'diagnostics',axleResultDiagnostics(search));
result.statistics=actuationResultStatistics(search,result.elapsedTime_s);
end
