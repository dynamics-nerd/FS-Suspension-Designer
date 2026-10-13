function evaluation = evaluateCore(space,u,id,solve,analyze)
%EVALUATECORE Explicit fresh BUMP -> native analysis -> v0.11 evaluation.
% Optional private handles are a test-only fault-injection seam, not a public API.
if nargin<4, solve=@fsd.kinematics.solveBumpSweep; end
if nargin<5, analyze=@fsd.analysis.analyzeBumpSweep; end
x = coordinateCore(space,u,"DENORMALIZE");
evaluation = struct('schemaVersion',"0.12.0",'kind',"SynthesisEvaluation", ...
    'execution',executionSnapshot(space),'bumpEvidence',[],'failureStage',"",'evidenceStatus',"NO_GEOMETRY", ...
    'evaluationId',id,'u',u(:),'x_m',x,'changes',{{}},'geometry',[], ...
    'geometryIdentity',[],'geometryValid',false,'candidate',[],'assessment',[], ...
    'quality',[],'solverStatus',"NOT_ATTEMPTED",'hardFeasibility',"NOT_EVALUATED", ...
    'classification',"INVALID_GEOMETRY",'eligible',false,'score',NaN,'reason',"", ...
    'exceptionId',"",'exceptionMessage',"",'solverCalls',0, ...
    'timing_s',struct('builder',0,'solver',0,'analysis',0,'evaluator',0,'total',0));
total = tic; timer = tic;
try
    [geometry,changes] = buildCore(space,x);
catch cause
    if ~recoverableFailure("BUILDER",cause.identifier), rethrow(cause); end
    evaluation.timing_s.builder = toc(timer); evaluation.timing_s.total = toc(total);
    evaluation.reason = "INVALID_GEOMETRY"; evaluation.exceptionId = string(cause.identifier);
    evaluation.exceptionMessage = string(cause.message); evaluation.failureStage="BUILDER"; return;
end
evaluation.timing_s.builder = toc(timer); evaluation.geometry = geometry; evaluation.changes = changes;
evaluation.geometryIdentity = fsd.model.geometryIdentity(geometry); evaluation.geometryValid = true;
evaluation.evidenceStatus="GEOMETRY_ONLY";
sources = cell(numel(space.sourceIds),1);
if ~isempty(sources)
    timer = tic;
    evaluation.solverCalls = 1;
    % Bind options at invocation, including attempts that return no sweep.
    evaluation.bumpEvidence=struct('execution',evaluation.execution,'evaluationId',id, ...
        'geometryIdentity',evaluation.geometryIdentity,'sweep',[]);
    try
        sweep = solve(geometry,evaluation.execution.travel_m,'m',evaluation.execution.solverOptions);
    catch cause
        if ~recoverableFailure("BUMP",cause.identifier), rethrow(cause); end
        evaluation.timing_s.solver=toc(timer); evaluation.solverStatus="EXCEPTION";
        evaluation=failedEvaluation(evaluation,"BUMP",cause,total); return;
    end
    evaluation.bumpEvidence.sweep=sweep; evaluation.evidenceStatus="BUMP_AVAILABLE";
    evaluation.timing_s.solver = toc(timer); timer = tic;
    evaluation.quality = bumpQuality(geometry,sweep);
    evaluation.solverStatus = "CONVERGED";
    if ~sweep.allConverged, evaluation.solverStatus = "PARTIAL_OR_FAILED"; end
    try
        analysis = analyze(geometry,sweep);
    catch cause
        if ~recoverableFailure("ANALYSIS",cause.identifier), rethrow(cause); end
        evaluation.timing_s.analysis=toc(timer);
        evaluation=failedEvaluation(evaluation,"ANALYSIS",cause,total); return;
    end
    evaluation.timing_s.analysis = toc(timer);
    for i=1:numel(sources)
        sources{i} = struct('id',space.sourceIds(i),'type',"BUMP",'model',geometry,'sweep',sweep,'result',analysis);
    end
else
    evaluation.solverStatus = "NOT_REQUIRED";
end
evaluation.candidate = fsd.model.createDesignCandidate(struct('id',"SYNTH_"+string(id), ...
    'geometries',{{geometry}},'sources',{sources},'metadata',struct('sourceKind',"DERIVED", ...
    'sourceNote',"Explicit v0.12 candidate reconstruction; seed and changed coordinates preserved")));
timer = tic;
evaluation.assessment = fsd.analysis.evaluateDesignCandidate(space.specification,evaluation.candidate);
evaluation.timing_s.evaluator = toc(timer);
evaluation.evidenceStatus="ASSESSED";
evaluation = classifyEvaluation(evaluation); evaluation.timing_s.total = toc(total);
end

function e = failedEvaluation(e,stage,cause,total)
e.failureStage=stage; e.exceptionId=string(cause.identifier); e.exceptionMessage=string(cause.message);
e=classifyEvaluation(e); e.timing_s.total=toc(total);
end
