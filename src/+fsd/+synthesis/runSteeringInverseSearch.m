function result = runSteeringInverseSearch(space,options)
%RUNSTEERINGINVERSESEARCH One shared v0.12 controller, one coordinated objective.
if nargin<2, options=struct(); end
fsd.synthesis.validateSteeringDesignSpace(space);
if exist('fsolve','file')~=2 || ~license('test','Optimization_Toolbox')
    error('fsd:synthesis:MissingKinematicDependency','Native BUMP/RACK/ROLL requires Optimization Toolbox/fsolve.');
end
execution=axleExecutionSnapshot(space); timer=tic;
initial=coordinateCore(space,space.initial_m,"NORMALIZE");
search=fsd.synthesis.boundedDirectSearch(initial,space.active,options, ...
    @(u,id) axleEvaluationCore(space,u,id),@(u) coordinateCore(space,u,"DENORMALIZE"));
result=struct('schemaVersion',"0.14.0",'kind',"SteeringSynthesisResult",'problem',space,'execution',execution, ...
    'search',search,'feasibleIndices',search.eligibleIndices,'selectedIndex',search.selectedIndex, ...
    'selectionPolicy',"BEST_EXPLICIT_SCORE_AMONG_EXPLORED_ELIGIBLE_ONLY",'elapsedTime_s',toc(timer), ...
    'diagnostics',axleResultDiagnostics(search));
result.statistics=axleResultStatistics(search,result.elapsedTime_s);
end
