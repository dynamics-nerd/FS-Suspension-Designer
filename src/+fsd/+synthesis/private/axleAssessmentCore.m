function e = axleAssessmentCore(space,e)
%AXLEASSESSMENTCORE One native v0.11 candidate/assessment for the entire axle.
sources=cell(0,1); models={e.axle.leftGeometry;e.axle.rightGeometry;e.axle};
for j=1:3
    evidence=e.physical{j}; if isempty(evidence) || isempty(evidence.analysis), continue; end
    for k=1:numel(space.sourceIds{j})
        sources{end+1,1}=struct('id',space.sourceIds{j}(k),'type',evidence.family, ...
            'model',models{j},'sweep',evidence.sweep,'result',evidence.analysis); %#ok<AGROW>
    end
end
e.candidate=fsd.model.createDesignCandidate(struct('id',"AXLE_SYNTH_"+string(e.evaluationId), ...
    'geometries',{{models{1};models{2}}},'sources',{sources}, ...
    'metadata',struct('sourceKind',"DERIVED",'sourceNote',"Coordinated v0.13 axle reconstruction and native evidence")));
timer=tic; e.assessment=fsd.analysis.evaluateDesignCandidate(space.specification,e.candidate);
e.timing_s.evaluator=toc(timer); e.hardFeasibility=e.assessment.hardFeasibility;
e.softScoreStatus=e.assessment.compositeScoreStatus;
e.analysisStatus=strings(3,1);
for j=1:3
    p=e.physical{j}; e.analysisStatus(j)="NOT_REQUESTED";
    if isempty(p), continue; end
    e.analysisStatus(j)="NOT_EVALUABLE";
    if ~isempty(p.analysis)
        e.analysisStatus(j)="PARTIAL_OR_UNRELIABLE";
        if p.quality.allReliable, e.analysisStatus(j)="RELIABLE_SAMPLES"; end
    end
end
e.evidenceStatus="ASSESSED_PARTIAL";
if all(ismember(e.analysisStatus,["RELIABLE_SAMPLES","NOT_REQUESTED"])), e.evidenceStatus="ASSESSED_COMPLETE"; end
e.eligible=false; e.score=NaN;
if e.hardFeasibility=="INFEASIBLE_FOR_SPECIFICATION"
    e.classification="HARD_CONSTRAINT_FAILED";
elseif e.analysisStatus(1)~="RELIABLE_SAMPLES"
    e.classification="LEFT_NOT_EVALUABLE";
elseif e.analysisStatus(2)~="RELIABLE_SAMPLES"
    e.classification="RIGHT_NOT_EVALUABLE";
elseif e.analysisStatus(3)~="NOT_REQUESTED" && e.analysisStatus(3)~="RELIABLE_SAMPLES"
    e.classification="JOINT_ANALYSIS_UNAVAILABLE";
elseif e.hardFeasibility=="INDETERMINATE_HARD_REQUIREMENTS"
    e.classification="INDETERMINATE";
elseif ~e.assessment.readiness.allRequirementsEvaluated
    e.classification="NOT_EVALUABLE";
else
    e.classification="SAMPLED_FEASIBLE"; e.eligible=true; e.score=e.assessment.compositeScore;
end
e.reason=e.classification;
end
