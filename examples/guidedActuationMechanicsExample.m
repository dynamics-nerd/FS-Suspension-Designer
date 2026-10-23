function output = guidedActuationMechanicsExample(file)
%GUIDEDACTUATIONMECHANICSEXAMPLE New v0.20 flow, explicit synthetic inputs only.
% Optional file is a NEW destination; existing evidence is never overwritten.
% No figures or fixed output paths. Call setupProject; addpath('app','examples').
if nargin<1, file=""; end
started=tic; before=[]; if ispc, before=memory; end
[g,a,~,definition,mechanical,units]=actuationSynthesisSeed('PUSHROD','FL');
concept=fsd.project.createVehicleConcept(struct('id',"GUIDED_MECHANICS_EXAMPLE"));
p=fsd.project.createEngineeringProject(struct('concept',concept,'resources',struct('geometries',{{g}})));
c=fsdui.Controller(p); cleanup=onCleanup(@()c.close());
stages=timed(c,'ACTUATION_CONFIG',struct('cornerId',"FL",'definition',definition,'lengthUnit',"m", ...
    'mechanicalDefinition',mechanical,'units',units));
plan=struct('travel_m',[-.01;0;.01]);
stages(end+1)=timed(c,'BUMP',struct('scope',"FL",'plan',plan,'resultId',"UNCHANGED_GEOMETRY"));
stages(end+1)=timed(c,'ACTUATION_RUN',struct('cornerId',"FL",'engine',"ACTUATION",'plan',plan,'resultId',"ACT"));
actuation=c.LastValue; plan.wheelVelocity_m_per_s=0; % explicit prescribed rest
stages(end+1)=timed(c,'ACTUATION_RUN',struct('cornerId',"FL",'engine',"MECHANICAL",'plan',plan,'resultId',"MECH"));
mechanics=c.LastValue;
% Independent native forward reference, outside the inverse-search budget.
reference=definition; reference.damper.chassisPoint(2)=reference.damper.chassisPoint(2)+.005;
referenceActuation=fsd.model.createActuationGeometry(g,reference,'m');
b=fsd.kinematics.solveBumpSweep(g,plan.travel_m,'m');
sweep=fsd.kinematics.solveActuationSweep(referenceActuation,b);
analysis=fsd.analysis.analyzeActuationSweep(referenceActuation,sweep);
point=a.damper.chassisPoint.point_m;
parameter=fsd.model.createDesignParameter(struct('id',"CHASSIS_Y",'quantity',"LENGTH", ...
    'scope',fsd.model.designScope('HARDPOINT','FL_DAMPER_CHASSIS','FL'),'binding',"HARDPOINT_Y", ...
    'type',"FREE",'value',point(2),'bounds',point(2)+[-.01,.01],'availability',"ASSUMED", ...
    'sourceKind',"ASSUMED",'sourceNote',"Synthetic +/-10 mm benchmark design window"),'m');
target=fsd.model.createDesignTarget(struct('id',"REFERENCE_MR",'metricId',"MOTION_RATIO", ...
    'sourceType',"ACTUATION",'sourceId',"ACT_FL",'scope',fsd.model.designScope('CORNER','FL'), ...
    'type',"CURVE_TARGET",'strength',"SOFT",'independentVariable',"WHEEL_TRAVEL", ...
    'x',plan.travel_m,'value',analysis.damperMotionRatio,'tolerance',1e-7, ...
    'normalizationScale',.1,'normalizationNote',"Explicit synthetic benchmark ratio scale",'weight',1, ...
    'sourceNote',"Independent native +5 mm chassis-Y reference, not FS advice"),'1','m');
spec=fsd.model.createDesignSpecification(struct('id',"GUIDED_MR",'parameters',{{parameter}}, ...
    'targets',fsd.model.createSuspensionDesignTargets({target}),'compositeScore',true));
origin=struct('targetId',"REFERENCE_MR",'kind',"DECLARED_REFERENCE", ...
    'reference',"Synthetic native chassis-Y +5 mm",'note',"Software verification, not a measured vehicle");
d=struct('id',"UI_ACT_SEARCH_FL",'engine',"ACTUATION_SYNTHESIS",'scope',fsd.model.designScope('CORNER','FL'), ...
    'specification',spec,'targetOrigins',{{origin}},'plan',plan,'options',struct('maxEvaluations',3, ...
    'maxIterations',1,'initialStep',.25,'minimumStep',.25,'stopAtScore',1e-10));
stages(end+1)=timed(c,'SPECIFICATION',struct('definition',d));
stages(end+1)=timed(c,'SYNTHESIS',struct('scenarioId',"UI_ACT_SEARCH_FL",'resultId',"SEARCH")); search=c.LastValue;
index=search.nativePayload.selectedIndex; assert(isfinite(index));
comparison=fsd.synthesis.compareActuationSynthesisCandidates(search.nativePayload,unique([1,index]));
stages(end+1)=timed(c,'ACTUATION_ADOPT',struct('resultId',"SEARCH",'index',index));
assert(isequaln(c.Project.definition.resources.geometries,{g}));
if strlength(string(file))>0
    stages(end+1)=timed(c,'SAVE',struct('file',string(file),'overwrite',false));
    recovered=fsd.project.loadEngineeringProject(file); assert(isequaln(recovered,c.Project));
end
after=[]; if ispc, after=memory; end
output=struct('project',c.Project,'actuation',actuation,'mechanics',mechanics,'search',search, ...
    'comparison',comparison,'referenceActuation',referenceActuation,'referenceAnalysis',analysis, ...
    'elapsed_s',toc(started),'memoryBefore',before,'memoryAfter',after,'stages',stages);
fprintf('GUIDED_ACTUATION_EXAMPLE: %d records, E%d, fixed suspension; %.3f s\n', ...
    numel(c.Project.definition.results),search.nativePayload.search.evaluationCount,output.elapsed_s);
end
function stage=timed(c,action,args)
started=tic; c.run(action,args,false); elapsed=toc(started);
bytes=[]; if ispc, snapshot=memory; bytes=snapshot.MemUsedMATLAB; end
stage=struct('action',string(action),'elapsed_s',elapsed,'matlabBytesAfter',bytes);
end
