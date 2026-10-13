function e = axleEvaluationCore(space,u,id,stored)
%AXLEEVALUATIONCORE Fresh joint pipeline or reconstruction from native evidence.
% STORED is private and solely selects algebraic replay, never a public adapter.
replay=nargin==4; x=coordinateCore(space,u,"DENORMALIZE");
requireSynthesis(isnumeric(id) && isreal(id) && isscalar(id) && isfinite(id) && id>=1 && id==fix(id),'Positive evaluation ID required.');
e=struct('schemaVersion',"0.13.0",'kind',"AxleSynthesisEvaluation",'execution',axleExecutionSnapshot(space), ...
    'evaluationId',id,'u',u(:),'x_m',x,'axle',[],'axleIdentity',[],'changes',{{}},'geometryValid',false, ...
    'physical',{{[];[];[]}},'candidate',[],'assessment',[],'failureStage',"",'exceptionId',"",'exceptionMessage',"", ...
    'evidenceStatus',"NO_GEOMETRY",'analysisStatus',repmat("NOT_ATTEMPTED",3,1), ...
    'hardFeasibility',"NOT_EVALUATED",'softScoreStatus',"NOT_EVALUATED", ...
    'classification',"INVALID_GEOMETRY",'reason',"INVALID_GEOMETRY",'eligible',false,'score',NaN, ...
    'timing_s',struct('builder',0,'evaluator',0,'total',0));
total=tic; timer=tic;
try
    [axle,changes]=axleBuildCore(space,x);
catch cause
    if ~recoverableFailure("BUILDER",cause.identifier), rethrow(cause); end
    e.failureStage="BUILDER"; e.exceptionId=string(cause.identifier); e.exceptionMessage=string(cause.message);
    e.timing_s.builder=toc(timer); e.timing_s.total=toc(total);
    if replay, finishReplay(); end
    return;
end
e.timing_s.builder=toc(timer); e.axle=axle; e.changes=changes; e.geometryValid=true;
e.axleIdentity=fsd.model.axleIdentity(axle);
models={axle.leftGeometry;axle.rightGeometry;axle}; plans={space.plan.leftBump;space.plan.rightBump;space.plan.roll};
for j=1:3
    if isempty(plans{j}), continue; end
    family="BUMP"; if j==3, family="ROLL"; end
    if replay, e.physical{j}=axlePhysicalCore(models{j},family,plans{j},e.execution,id,stored.physical{j});
    else, e.physical{j}=axlePhysicalCore(models{j},family,plans{j},e.execution,id); end
end
e=axleAssessmentCore(space,e); e.timing_s.total=toc(total);
if replay, finishReplay(); end

    function finishReplay()
        t=stored.timing_s;
        requireSynthesis(isequal(sort(string(fieldnames(t))),sort(["builder";"evaluator";"total"])) && ...
            isnumeric([t.builder,t.evaluator,t.total]) && isreal([t.builder,t.evaluator,t.total]) && ...
            all(isfinite([t.builder,t.evaluator,t.total])) && all([t.builder,t.evaluator,t.total]>=0),'Invalid axle timing.');
        if ~e.geometryValid, requireSynthesis(t.evaluator==0,'Rejected builder cannot have an assessment time.'); end
        physicalTime=0;
        for k=1:3
            p=e.physical{k}; if ~isempty(p), physicalTime=physicalTime+p.solverTime_s+p.analysisTime_s; end
        end
        requireSynthesis(t.total>=t.builder+t.evaluator+physicalTime,'Total time smaller than executed phases.');
        e.timing_s=t;
        requireSynthesis(isequaln(axleComparable(e),axleComparable(stored)),'Axle evaluation binding or assessment mismatch.');
        e=stored;
    end
end
