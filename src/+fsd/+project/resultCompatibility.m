function report = resultCompatibility(result,project)
%RESULTCOMPATIBILITY Current execution versus reusable dependencies versus stale.
fsd.project.validateEngineeringResult(result); fsd.project.validateEngineeringProject(project);
report=struct('status',"INCOMPATIBLE",'executedRevision',result.projectRevision, ...
    'currentRevision',project.definition.revision,'diagnostics',strings(0,1));
if result.projectId~=project.id, report.diagnostics="Different project ID."; return; end
ids=strings(numel(project.definition.scenarios),1);
for j=1:numel(ids), ids(j)=project.definition.scenarios{j}.definition.id; end
id=result.scenarioAtExecution.definition.id;
if ~ismember(id,ids), report.diagnostics="Original scenario no longer exists."; return; end
p=prepareScenarioCore(project,scenarioFind(project,id));
if p.readiness.status~="READY"
    report.status="STALE"; report.diagnostics=[p.readiness.missing;p.readiness.diagnostics]; return;
end
if ~isequaln(p.context,result.prepared.context)
    report.status="STALE"; report.diagnostics="Relevant model, concept dependency, target, plan, architecture or control changed."; return;
end
if isequaln(result.projectIdentity,project.identity), report.status="CURRENT_EXECUTION";
else
    report.status="REUSABLE_DEPENDENCIES";
    report.diagnostics="Dependencies unchanged; evidence still belongs to its original execution revision, not a new run.";
end
end
