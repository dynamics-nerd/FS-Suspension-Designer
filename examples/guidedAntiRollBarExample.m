function output=guidedAntiRollBarExample(file)
%GUIDEDANTIROLLBAREXAMPLE Native geometric design/global/history with explicit data.
% All inputs are synthetic assumptions, not measured/recommended Formula Student data.
% Optional new MAT filename; existing files are never overwritten.
if nargin<1, file=""; end
started=tic; [p,globalDefinition]=globalStaticGuidedInputs;
c=fsdui.Controller(p); cleanup=onCleanup(@()c.close()); stages=timed(c,'GLOBAL_CONFIG',struct('definition',globalDefinition));
stages(end+1)=timed(c,'GLOBAL_RUN',struct('scenarioId',globalDefinition.id,'resultId',"GLOBAL_WITHOUT_ARB"));
without=c.LastValue;
d=geometricAntiRollBarInputs(c.Project,'FRONT','ROCKER');
stages(end+1)=timed(c,'ARB_CONFIG',struct('definition',d)); bar=c.LastValue;
z=linspace(-.01,.01,21)'; plan=struct('wheelTravel_m',[z,-z], ...
    'driverTravel_m',{{(-.02:.004:.02)',(-.02:.004:.02)'}},'packaging',antiRollBarPackagingInputs(bar));
sd=struct('id',"ARB_DESIGN",'engine',"ARB_MECHANICAL",'scope',fsd.model.designScope('AXLE','FRONT'), ...
    'inputs',struct('arbId',bar.definition.id,'arbRevision',bar.definition.revision),'plan',plan);
stages(end+1)=timed(c,'ARB_STUDY_CONFIG',struct('definition',sd)); assert(c.LastValue.status=="READY");
stages(end+1)=timed(c,'ARB_RUN',struct('scenarioId',sd.id,'resultId',"ARB_BASELINE")); first=c.LastValue;
d=bar.definition; d.adjustmentId="DECLARED_STIFFER_PORTS"; d.parameters.kTheta_Nm_per_rad=150;
d.provenance.kTheta_Nm_per_rad.sourceNote="Explicit alternative 150 Nm/rad port law; not an optimum";
stages(end+1)=timed(c,'ARB_CONFIG',struct('definition',d)); bar=c.LastValue; sd.inputs.arbRevision=bar.definition.revision;
stages(end+1)=timed(c,'ARB_STUDY_CONFIG',struct('definition',sd));
stages(end+1)=timed(c,'ARB_RUN',struct('scenarioId',sd.id,'resultId',"ARB_VARIANT")); second=c.LastValue;
comparison=fsd.analysis.compareAntiRollBarResponses(first.nativePayload.study,second.nativePayload.study);
assert(comparison.compatibleConditions);
d=bar.definition; d.section="SOLID"; d.parameters.G_Pa=8e10; d.parameters.effectiveLength_m=.5;
for key=["G_Pa","effectiveLength_m"], d.provenance.(key)=struct('sourceKind',"ASSUMED",'sourceNote',"Explicit scalar sizing benchmark"); end
stages(end+1)=timed(c,'ARB_CONFIG',struct('definition',d)); bar=c.LastValue;
target=struct('stiffness_Nm_per_rad',100,'sourceKind',"KNOWN",'sourceNote',"User-chosen scalar example target; not generated from vehicle performance");
sizeDefinition=struct('id',"ARB_SHAFT_SIZE",'engine',"ARB_SIZING",'scope',fsd.model.designScope('AXLE','FRONT'), ...
    'inputs',struct('arbId',bar.definition.id,'arbRevision',bar.definition.revision),'plan',struct('target',target));
stages(end+1)=timed(c,'ARB_STUDY_CONFIG',struct('definition',sizeDefinition));
stages(end+1)=timed(c,'ARB_RUN',struct('scenarioId',sizeDefinition.id,'resultId',"ARB_SECTION_SIZE")); sizing=c.LastValue;
d=bar.definition; d.referenceMode="DECLARED_FREE"; d.adjustmentId="DECLARED_PRELOADED_GLOBAL_COMPARISON";
d.parameters.freeAngle_rad=diff(d.parameters.installationAngles_rad)-.005;
d.provenance.freeAngle_rad=struct('sourceKind',"ASSUMED", ...
    'sourceNote',"Explicit synthetic installed pre-twist 0.005 rad; free=installed difference minus 0.005, not an optimal setup");
stages(end+1)=timed(c,'ARB_CONFIG',struct('definition',d)); bar=c.LastValue;
assignment=struct('axleId',"FRONT",'arbId',bar.definition.id,'arbRevision',bar.definition.revision);
stages(end+1)=timed(c,'ARB_ASSIGN',struct('assignments',{{assignment}}));
globalDefinition.inputs.arbAxles="FRONT";
stages(end+1)=timed(c,'GLOBAL_CONFIG',struct('definition',globalDefinition)); assert(c.LastValue.status=="READY");
stages(end+1)=timed(c,'GLOBAL_RUN',struct('scenarioId',globalDefinition.id,'resultId',"GLOBAL_WITH_ARB")); with=c.LastValue;
assert(isfinite(with.nativePayload.equilibrium.selectedIndex));
assert(fsd.project.resultCompatibility(without,c.Project).status=="STALE");
records=c.Project.definition.results; original=records(cellfun(@(r)r.id==without.id,records)); assert(isequaln(original{1},without));
if strlength(string(file))>0
    stages(end+1)=timed(c,'SAVE',struct('file',string(file),'overwrite',false)); expected=c.Project;
    stages(end+1)=timed(c,'LOAD',struct('file',string(file))); assert(isequaln(c.Project,expected));
end
output=struct('project',c.Project,'first',first,'second',second,'comparison',comparison, ...
    'sizing',sizing,'without',without,'with',with,'stages',stages,'elapsed_s',toc(started));
fprintf('ARB_GUIDED_EXAMPLE elapsed_s=%.6f records=%d\n',output.elapsed_s,numel(c.Project.definition.results));
end
function s=timed(c,action,args)
before=NaN; if ispc, m=memory; before=m.MemUsedMATLAB; end
timer=tic; c.run(action,args,false); elapsed=toc(timer);
after=NaN; if ispc, m=memory; after=m.MemUsedMATLAB; end
s=struct('action',string(action),'elapsed_s',elapsed,'matlabBytesBefore',before,'matlabBytesAfter',after);
end
