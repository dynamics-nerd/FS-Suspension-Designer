function e = actuationEvaluationCore(space,u,id,stored)
%ACTUATIONEVALUATIONCORE Native physical execution or strictly algebraic replay.
replay=nargin==4; x=coordinateCore(space,u,"DENORMALIZE");
requireSynthesis(isnumeric(id) && isreal(id) && isscalar(id) && isfinite(id) && id>=1 && id==fix(id), ...
    'Positive integer evaluation ID required.');
e=struct('schemaVersion',"0.15.0",'kind',"ActuationSynthesisEvaluation", ...
    'execution',actuationExecutionSnapshot(space),'evaluationId',id,'u',double(u(:)),'x_m',x, ...
    'geometry',[],'geometryIdentity',[],'actuation',[],'actuationIdentity',[], ...
    'mechanical',[],'mechanicalIdentity',[],'changes',{{}},'builderDiagnostics',[], ...
    'geometryValid',false,'preflightAssessment',[],'candidate',[],'assessment',[], ...
    'bumpEvidence',[],'actuationEvidence',[],'mechanicalEvidence',[], ...
    'failureStage',"",'exceptionId',"",'exceptionMessage',"",'evidenceStatus',"NO_GEOMETRY", ...
    'hardFeasibility',"NOT_EVALUATED",'softScoreStatus',"NOT_EVALUATED", ...
    'classification',"INVALID_GEOMETRY",'reason',"INVALID_GEOMETRY",'eligible',false,'score',NaN, ...
    'timing_s',struct('builder',0,'evaluator',0,'total',0));
total=tic; timer=tic;
try
    [a,m,changes,diagnostics]=actuationBuildCore(space,x);
catch cause
    if ~ismember(string(cause.identifier),["fsd:synthesis:ZeroLengthActuationRod", ...
            "fsd:synthesis:ZeroLengthActuationDamper","fsd:model:RockerLeverArmDegenerate", ...
            "fsd:model:RockerDamperLeverArmDegenerate"])
        rethrow(cause);
    end
    e.failureStage="BUILDER"; e.exceptionId=string(cause.identifier); e.exceptionMessage=string(cause.message);
    e.timing_s.builder=toc(timer); e.timing_s.total=toc(total);
    if replay, finishReplay(); end
    return;
end
e.timing_s.builder=toc(timer); e.geometry=space.seed; e.geometryIdentity=space.seedIdentity;
e.actuation=a; e.actuationIdentity=a.identity; e.mechanical=m;
if ~isempty(m), e.mechanicalIdentity=m.identity; end
e.changes=changes; e.builderDiagnostics=diagnostics; e.geometryValid=true;
e.candidate=candidate(cell(0,1)); timer=tic;
e.preflightAssessment=fsd.analysis.evaluateDesignCandidate(space.specification,e.candidate);
e.timing_s.evaluator=toc(timer);
if e.preflightAssessment.hardFeasibility=="INFEASIBLE_FOR_SPECIFICATION"
    e.assessment=e.preflightAssessment; e.evidenceStatus="NOMINAL_HARD_REJECTED";
    classify(); e.timing_s.total=toc(total);
    if replay, finishReplay(); end
    return;
end
bumpPlan=rmfield(space.plan,'wheelVelocity_m_per_s');
if replay
    e.bumpEvidence=axlePhysicalCore(space.seed,"BUMP",bumpPlan,e.execution,id,stored.bumpEvidence);
else
    e.bumpEvidence=axlePhysicalCore(space.seed,"BUMP",bumpPlan,e.execution,id);
end
b=e.bumpEvidence; sources=cell(0,1);
if ~isempty(b.analysis), appendSources(1,space.seed,b.sweep,b.analysis,[]); end
if ~isempty(b.sweep)
    p=struct('family',"ACTUATION",'execution',e.execution,'evaluationId',id,'modelIdentity',a.identity, ...
        'solverCalls',1,'sweep',[],'analysis',[],'solverTime_s',0,'analysisTime_s',0);
    if replay
        p.sweep=stored.actuationEvidence.sweep;
    else
        timer=tic; p.sweep=fsd.kinematics.solveActuationSweep(a,b.sweep); p.solverTime_s=toc(timer);
    end
    fsd.kinematics.validateActuationSweepResult(p.sweep,a);
    requireSynthesis(isequaln(p.sweep.requestedWheelTravel_m,space.plan.travel_m), 'Actuation grid mismatch.');
    for j=1:numel(p.sweep.results)
        requireSynthesis(isequaln(p.sweep.results(j).sourceResult,b.sweep.results(j)), 'Actuation reuses another BUMP state.');
    end
    timer=tic; p.analysis=fsd.analysis.analyzeActuationSweep(a,p.sweep); p.analysisTime_s=toc(timer);
    if replay, p=physicalReplay(p,stored.actuationEvidence); end
    e.actuationEvidence=p; appendSources(2,a,p.sweep,p.analysis,[]);
    if ~isempty(m)
        q=struct('family',"MECHANICAL",'execution',e.execution,'evaluationId',id,'modelIdentity',m.identity, ...
            'analysisCalls',1,'analysis',[],'analysisTime_s',0);
        timer=tic;
        q.analysis=fsd.analysis.analyzeSpringDamperSweep(m,a,p.sweep,p.analysis,space.plan.wheelVelocity_m_per_s,'m/s');
        q.analysisTime_s=toc(timer);
        if replay, q=physicalReplay(q,stored.mechanicalEvidence); end
        e.mechanicalEvidence=q; appendSources(3,m,[],q.analysis,a);
    end
end
e.candidate=candidate(sources); timer=tic;
e.assessment=fsd.analysis.evaluateDesignCandidate(space.specification,e.candidate);
e.timing_s.evaluator=e.timing_s.evaluator+toc(timer); e.evidenceStatus="ASSESSED";
classify(); e.timing_s.total=toc(total);
if replay, finishReplay(); end

    function c = candidate(available)
        c=fsd.model.createDesignCandidate(struct('id',"ACTUATION_SYNTH_"+string(id), ...
            'geometries',{{space.seed}},'actuations',{{a}},'sources',{available}, ...
            'metadata',struct('sourceKind',"DERIVED",'sourceNote',"v0.15 fixed suspension and reconstructed actuation")));
    end
    function appendSources(family,model,sweep,result,auxiliary)
        families=["BUMP","ACTUATION","MECHANICAL"];
        for k=1:numel(space.sourceIds{family})
            sources{end+1,1}=struct('id',space.sourceIds{family}(k),'type',families(family), ...
                'model',model,'sweep',sweep,'result',result,'auxiliary',auxiliary); %#ok<AGROW>
        end
    end
    function classify()
        e.hardFeasibility=e.assessment.hardFeasibility; e.softScoreStatus=e.assessment.compositeScoreStatus;
        if e.hardFeasibility=="INFEASIBLE_FOR_SPECIFICATION"
            e.classification="HARD_CONSTRAINT_FAILED";
        elseif isempty(e.bumpEvidence) || isempty(e.bumpEvidence.sweep) || ~e.bumpEvidence.quality.allReliable
            e.classification="BUMP_NOT_RELIABLE";
        elseif isempty(e.actuationEvidence) || ~all(e.actuationEvidence.sweep.converged & ...
                ~reshape([e.actuationEvidence.sweep.results.isIllConditioned],[],1))
            e.classification="ACTUATION_NOT_RELIABLE";
        elseif ~isempty(e.mechanicalEvidence) && ~all(e.mechanicalEvidence.analysis.feasibleRelativeToProvidedLimits)
            e.classification="MECHANICAL_LIMIT_FAILED";
        elseif e.hardFeasibility=="INDETERMINATE_HARD_REQUIREMENTS"
            e.classification="INDETERMINATE";
        elseif ~e.assessment.readiness.allRequirementsEvaluated
            e.classification="NOT_EVALUABLE";
        else
            e.classification="SAMPLED_FEASIBLE"; e.eligible=true; e.score=e.assessment.compositeScore;
        end
        e.reason=e.classification;
    end
    function p = physicalReplay(p,previous)
        requireSynthesis(isnumeric(previous.analysisTime_s) && isscalar(previous.analysisTime_s) && ...
            isfinite(previous.analysisTime_s) && previous.analysisTime_s>=0,'Invalid analysis timing.');
        p.analysisTime_s=previous.analysisTime_s;
        if isfield(p,'solverTime_s')
            requireSynthesis(isnumeric(previous.solverTime_s) && isscalar(previous.solverTime_s) && ...
                isfinite(previous.solverTime_s) && previous.solverTime_s>=0,'Invalid solver timing.');
            p.solverTime_s=previous.solverTime_s;
        end
        requireSynthesis(isequaln(axleComparable(p),axleComparable(previous)), 'Actuation/mechanical evidence contradicts context.');
        p=previous;
    end
    function finishReplay()
        t=stored.timing_s;
        requireSynthesis(isequal(sort(string(fieldnames(t))),sort(["builder";"evaluator";"total"])) && ...
            isnumeric([t.builder,t.evaluator,t.total]) && isreal([t.builder,t.evaluator,t.total]) && ...
            all(isfinite([t.builder,t.evaluator,t.total]) & [t.builder,t.evaluator,t.total]>=0),'Invalid evaluation timing.');
        phases=t.builder+t.evaluator;
        if ~isempty(e.bumpEvidence), phases=phases+e.bumpEvidence.solverTime_s+e.bumpEvidence.analysisTime_s; end
        if ~isempty(e.actuationEvidence), phases=phases+e.actuationEvidence.solverTime_s+e.actuationEvidence.analysisTime_s; end
        if ~isempty(e.mechanicalEvidence), phases=phases+e.mechanicalEvidence.analysisTime_s; end
        requireSynthesis(t.total>=phases,'Total time smaller than reported phases.');
        if ~e.geometryValid, requireSynthesis(t.evaluator==0,'Builder failure cannot contain assessment time.'); end
        e.timing_s=t; requireSynthesis(isequaln(axleComparable(e),axleComparable(stored)), 'Evaluation contradicts reconstructed evidence.');
        e=stored;
    end
end
