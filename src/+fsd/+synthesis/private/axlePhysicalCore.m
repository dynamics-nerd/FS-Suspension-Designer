function evidence = axlePhysicalCore(model,family,plan,execution,id,stored)
%AXLEPHYSICALCORE Native invocation or algebraic evidence reconstruction (no solve).
replay=nargin==6;
requireSynthesis(ismember(family,["BUMP","ROLL","RACK"]),'Unknown native physical family.');
if family=="BUMP"
    identity=fsd.model.geometryIdentity(model); scope=model.cornerId;
elseif family=="RACK"
    identity=model.identity; scope="FRONT";
else
    identity=fsd.model.axleIdentity(model); scope=model.axleId;
end
evidence=struct('family',family,'scopeId',scope,'execution',execution,'evaluationId',id, ...
    'modelIdentity',identity,'solverCalls',1,'failureStage',"",'exceptionId',"",'exceptionMessage',"", ...
    'sweep',[],'analysis',[],'quality',[],'solverStatus',"EXCEPTION",'solverTime_s',0,'analysisTime_s',0);
if replay
    if stored.failureStage=="SOLVER"
        requireSynthesis(recoverableFailure("BUMP",stored.exceptionId) && strlength(stored.exceptionMessage)>0, ...
            'Unrecognized solver exception evidence.');
        evidence.failureStage="SOLVER"; evidence.exceptionId=stored.exceptionId; evidence.exceptionMessage=stored.exceptionMessage;
        finishReplay(); return;
    end
    sweep=stored.sweep;
else
    timer=tic;
    try
        if family=="BUMP"
            sweep=fsd.kinematics.solveBumpSweep(model,plan.travel_m,'m',plan.solverOptions);
        elseif family=="RACK"
            sweep=fsd.kinematics.solveRackSweep(model,plan.travel_m,plan.wheelTravel_m,'m',plan.solverOptions);
        else
            sweep=fsd.kinematics.solveAxleRollSweep(model,plan.angles_rad,plan.axleHeave_m,'rad','m',plan.solverOptions);
        end
    catch cause
        if ~recoverableFailure("BUMP",cause.identifier), rethrow(cause); end
        evidence.solverTime_s=toc(timer); evidence.failureStage="SOLVER";
        evidence.exceptionId=string(cause.identifier); evidence.exceptionMessage=string(cause.message); return;
    end
    evidence.solverTime_s=toc(timer);
end
evidence.sweep=sweep; evidence.solverStatus="CONVERGED";
if ~sweep.allConverged, evidence.solverStatus="PARTIAL_OR_FAILED"; end
if family=="BUMP"
    fsd.kinematics.validateBumpSweepResult(sweep);
    requireSynthesis(isequaln(sweep.geometryIdentity,identity) && isequaln(sweep.requestedWheelTravel_m,plan.travel_m), ...
        'BUMP model/grid mismatch.');
    evidence.quality=bumpQuality(model,sweep);
elseif family=="RACK"
    fsd.kinematics.validateRackSweepResult(sweep,model);
    requireSynthesis(isequaln(sweep.steeringSystemIdentity,identity) && isequaln(sweep.requestedRackTravel_m,plan.travel_m) && ...
        isequaln(sweep.requestedWheelTravel_m,plan.wheelTravel_m),'RACK model/grid/wheel travel mismatch.');
    for k=1:numel(sweep.results)
        requireSynthesis(isequaln(sweep.results(k).requestedWheelTravel_m,plan.wheelTravel_m),'RACK contained wheel travel mismatch.');
    end
    evidence.quality=rackQuality(model,sweep);
else
    fsd.kinematics.validateAxleRollSweepResult(sweep);
    requireSynthesis(isequaln(sweep.axleIdentity,identity) && isequaln(sweep.requestedBodyRollAngle_rad,plan.angles_rad) && ...
        sweep.requestedAxleHeave_m==plan.axleHeave_m,'ROLL model/grid/heave mismatch.');
    evidence.quality=rollQuality(model,sweep);
end
timer=tic;
try
    if family=="BUMP"
        evidence.analysis=fsd.analysis.analyzeBumpSweep(model,sweep);
    elseif family=="RACK"
        evidence.analysis=fsd.analysis.analyzeRackSweep(model,sweep);
    else
        evidence.analysis=fsd.analysis.analyzeAxleRollSweep(model,sweep);
    end
catch cause
    expected=recoverableFailure("ANALYSIS",cause.identifier);
    if family=="RACK", expected=steeringRecoverableFailure("ANALYSIS",cause.identifier); end
    if ~expected, rethrow(cause); end
    evidence.failureStage="ANALYSIS"; evidence.exceptionId=string(cause.identifier); evidence.exceptionMessage=string(cause.message);
end
evidence.analysisTime_s=toc(timer);
if replay, finishReplay(); end

    function finishReplay()
        times=[stored.solverTime_s,stored.analysisTime_s];
        requireSynthesis(isnumeric(times) && isreal(times) && isequal(size(times),[1,2]) && ...
            all(isfinite(times) & times>=0),'Invalid physical timing.');
        if evidence.failureStage=="SOLVER", requireSynthesis(times(2)==0,'Analysis was not attempted.'); end
        evidence.solverTime_s=times(1); evidence.analysisTime_s=times(2);
        requireSynthesis(isequaln(axleComparable(evidence),axleComparable(stored)), ...
            'Evidence, native payload, diagnostics or execution provenance mismatch.');
        % Preserve original native timing for exact source aliases/candidate binding.
        evidence=stored;
    end
end

function quality = rollQuality(axle,sweep)
% Apply the unchanged v0.12 local closure guard to each accepted native pose.
count=numel(sweep.results); left=cell(count,1); right=left; reliable=false(count,1);
for i=1:count
    r=sweep.results(i); if ~r.converged, continue; end
    travel=r.axleTravelResult;
    left{i}=bumpQuality(axle.leftGeometry,struct('results',travel.leftResult,'converged',true));
    right{i}=bumpQuality(axle.rightGeometry,struct('results',travel.rightResult,'converged',true));
    reliable(i)=left{i}.allReliable && right{i}.allReliable;
end
quality=struct('policy',"NATIVE_ROLL_WITH_LOCAL_CORNER_CLOSURE_GUARDS",'left',{left},'right',{right}, ...
    'reliable',reliable,'connected',reliable(1:end-1)&reliable(2:end),'allReliable',all(reliable));
end
