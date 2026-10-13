function valid = validateSynthesisEvaluation(evaluation,space)
%VALIDATESYNTHESISEVALUATION Rebuild geometry and assess native provenance; no solves.
fsd.synthesis.validateDesignSpace(space);
try
    e = evaluation;
    requireSynthesis(e.kind=="SynthesisEvaluation" && e.schemaVersion=="0.12.0" && ...
        isnumeric(e.evaluationId) && isreal(e.evaluationId) && isscalar(e.evaluationId) && isfinite(e.evaluationId) && e.evaluationId>=1 && ...
        fix(e.evaluationId)==e.evaluationId,'Invalid evaluation schema/ID.');
    requireSynthesis(islogical(e.geometryValid) && isscalar(e.geometryValid) && ...
        islogical(e.eligible) && isscalar(e.eligible) && isnumeric(e.score) && isreal(e.score) && isscalar(e.score) && ...
        isstring(e.failureStage) && isscalar(e.failureStage) && isstring(e.evidenceStatus) && isscalar(e.evidenceStatus) && ...
        isstring(e.exceptionId) && isscalar(e.exceptionId) && isstring(e.exceptionMessage) && isscalar(e.exceptionMessage), ...
        'Invalid evaluation flags/diagnostic types.');
    requireSynthesis(isequaln(e.execution,executionSnapshot(space)),'Execution plan provenance mismatch.');
    x=coordinateCore(space,e.u,"DENORMALIZE"); requireSynthesis(isequaln(x,e.x_m),'Vector mismatch.');
    failed=false;
    try
        [geometry,changes]=buildCore(space,x);
    catch cause
        if ~recoverableFailure("BUILDER",cause.identifier), rethrow(cause); end
        failed=true; requireSynthesis(~e.geometryValid && isempty(e.geometry) && isempty(e.geometryIdentity) && ...
            isempty(e.candidate) && isempty(e.assessment) && isempty(e.quality) && isempty(e.changes) && ...
            e.exceptionId==string(cause.identifier) && e.exceptionMessage==string(cause.message) && ...
            e.solverStatus=="NOT_ATTEMPTED" && e.hardFeasibility=="NOT_EVALUATED" && e.solverCalls==0 && ...
            e.failureStage=="BUILDER" && e.evidenceStatus=="NO_GEOMETRY" && isempty(e.bumpEvidence) && ...
            e.timing_s.solver==0 && e.timing_s.analysis==0 && e.timing_s.evaluator==0,'Invalid geometry diagnostic mismatch.');
    end
    if ~failed
        requireSynthesis(e.geometryValid && isequaln(e.geometry,geometry) && isequaln(e.changes,changes) && ...
            isequaln(e.geometryIdentity,fsd.model.geometryIdentity(geometry)),'Rebuilt geometry mismatch.');
        if ~isempty(space.sourceIds)
            b=e.bumpEvidence;
            requireSynthesis(isequaln(b.execution,e.execution) && b.evaluationId==e.evaluationId && ...
                isequaln(b.geometryIdentity,e.geometryIdentity) && ...
                isequal(sort(string(fieldnames(b))),sort(["execution";"evaluationId";"geometryIdentity";"sweep"])), ...
                'BUMP evidence execution binding mismatch.');
        else
            requireSynthesis(isempty(e.bumpEvidence),'Unrequested BUMP evidence.');
        end
        if strlength(e.failureStage)>0
            validateFailedPipeline(e,space,geometry);
        else
            requireSynthesis(strlength(e.exceptionId)==0 && strlength(e.exceptionMessage)==0 && ...
                e.evidenceStatus=="ASSESSED",'Unexpected failure/availability diagnostics.');
            candidate=e.candidate; fsd.analysis.validateDesignCandidate(candidate);
            requireSynthesis(candidate.definitionSI.id=="SYNTH_"+string(e.evaluationId) && ...
                isequaln(candidate.definitionSI.geometries,{geometry}) && isempty(candidate.definitionSI.vehicle), 'Candidate binding mismatch.');
            sources=candidate.definitionSI.sources;
            requireSynthesis(numel(sources)==numel(space.sourceIds),'Source count mismatch.');
            quality=[]; solverStatus="NOT_REQUIRED";
            for i=1:numel(sources)
                s=sources{i}; requireSynthesis(s.id==space.sourceIds(i) && s.type=="BUMP" && ...
                    isequaln(s.model,geometry) && isequaln(s.sweep.requestedWheelTravel_m,space.plan.travel_m), 'Source plan/geometry mismatch.');
                requireSynthesis(isequaln(s.sweep,e.bumpEvidence.sweep),'Source differs from execution evidence.');
                if i>1, requireSynthesis(isequaln(s.sweep,sources{1}.sweep),'Duplicate source aliases must share native evidence.'); end
                quality=bumpQuality(geometry,s.sweep); solverStatus="CONVERGED";
                if ~s.sweep.allConverged, solverStatus="PARTIAL_OR_FAILED"; end
            end
            requireSynthesis(isequaln(e.quality,quality) && e.solverStatus==solverStatus && ...
                e.solverCalls==double(~isempty(sources)),'Solver quality/count mismatch.');
            fsd.analysis.validateDesignAssessment(e.assessment,space.specification,candidate);
            requireSynthesis(e.hardFeasibility==e.assessment.hardFeasibility,'HARD assessment mismatch.');
        end
    end
    expected=classifyEvaluation(e);
    requireSynthesis(e.eligible==expected.eligible && isequaln(e.score,expected.score) && ...
        e.classification==expected.classification && e.reason==e.classification,'Classification/score mismatch.');
    t=e.timing_s; values=[t.builder,t.solver,t.analysis,t.evaluator,t.total];
    requireSynthesis(all(isfinite(values) & values>=0) && ...
        isequal(sort(string(fieldnames(t))),sort(["builder";"solver";"analysis";"evaluator";"total"])), 'Invalid timing diagnostics.');
catch cause
    exception=MException('fsd:synthesis:InvalidEvaluation','Synthesis evaluation is inconsistent with inputs/native evidence.');
    throwAsCaller(addCause(exception,cause));
end
valid=true;
end

function validateFailedPipeline(e,space,geometry)
requireSynthesis(~isempty(space.sourceIds) && recoverableFailure(e.failureStage,e.exceptionId) && ...
    isstring(e.exceptionMessage) && isscalar(e.exceptionMessage) && strlength(e.exceptionMessage)>0 && ...
    isempty(e.candidate) && isempty(e.assessment) && e.hardFeasibility=="NOT_EVALUATED" && ...
    e.solverCalls==1 && e.timing_s.evaluator==0,'Invalid pipeline failure record.');
if e.failureStage=="BUMP"
    % No completed sweep exists: do not manufacture or re-solve one to validate.
    requireSynthesis(isempty(e.bumpEvidence.sweep) && isempty(e.quality) && ...
        e.solverStatus=="EXCEPTION" && e.evidenceStatus=="GEOMETRY_ONLY" && ...
        e.timing_s.analysis==0,'BUMP exception evidence mismatch.');
else
    sweep=e.bumpEvidence.sweep; fsd.kinematics.validateBumpSweepResult(sweep);
    requireSynthesis(isequaln(sweep.geometryIdentity,e.geometryIdentity) && ...
        isequaln(sweep.requestedWheelTravel_m,space.plan.travel_m) && ...
        isequaln(e.quality,bumpQuality(geometry,sweep)) && e.evidenceStatus=="BUMP_AVAILABLE", ...
        'Analysis failure upstream evidence mismatch.');
    status="CONVERGED"; if ~sweep.allConverged, status="PARTIAL_OR_FAILED"; end
    requireSynthesis(e.solverStatus==status,'Analysis failure solver status mismatch.');
    observed=false;
    try
        fsd.analysis.analyzeBumpSweep(geometry,sweep);
    catch cause
        observed=true;
        requireSynthesis(recoverableFailure("ANALYSIS",cause.identifier) && ...
            e.exceptionId==string(cause.identifier) && e.exceptionMessage==string(cause.message), ...
            'Analysis diagnostic cannot be reconstructed.');
    end
    requireSynthesis(observed,'Declared analysis exception is not present in native evidence.');
end
end
